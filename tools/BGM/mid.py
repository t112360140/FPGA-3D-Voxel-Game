import mido
import math

def convert_midi_to_quartus_hex(midi_path):
    print(f"正在讀取 MIDI 檔案: {midi_path}")
    
    try:
        mid = mido.MidiFile(midi_path)
    except Exception as e:
        print(f"讀取 MIDI 檔案失敗: {e}")
        return

    events = [] 
    current_time = 0.0
    for msg in mid:
        current_time += msg.time * 1000.0 
        if msg.type == 'note_on' and msg.velocity > 0:
            events.append((current_time, 'on', msg.note, msg.velocity))
        elif msg.type == 'note_off' or (msg.type == 'note_on' and msg.velocity == 0):
            events.append((current_time, 'off', msg.note, 0))
            
    events.sort(key=lambda x: x[0])
    if not events: return

    total_ms = int(math.ceil(events[-1][0]))
    event_idx = 0
    raw_64bit_data = []
    
    # 記錄每個頻道的狀態：(note, vol)
    current_ch = [(0,0), (0,0), (0,0), (0,0)]
    prev_ch = [(0,0), (0,0), (0,0), (0,0)]
    duration_acc = 0

    for ms in range(total_ms + 100):
        state_changed = False
        
        # 處理同一時間點的所有 MIDI 事件
        while event_idx < len(events) and events[event_idx][0] <= ms:
            _, e_type, note, vol = events[event_idx]
            
            if e_type == 'on': 
                if vol > 90:
                    compressed_vol = 90 + (vol - 90) * 0.5
                else:
                    compressed_vol = vol

                scaled_vol = int((compressed_vol / 127.0) * 31)
                if scaled_vol == 0: scaled_vol = 1

                
                assigned = False
                for i in range(4):
                    if current_ch[i][0] == note: # 找到了！音符重複
                        current_ch[i] = (note, scaled_vol) # 只更新音量
                        assigned = True
                        state_changed = True
                        break
                        
                # 如果這是一個全新的音，才去找空位塞
                if not assigned:
                    for i in range(4):
                        if current_ch[i][0] == 0:
                            current_ch[i] = (note, scaled_vol)
                            state_changed = True
                            break 
            elif e_type == 'off':
                # 找到對應的音符並將頻道清空為 (0,0)
                for i in range(4):
                    if current_ch[i][0] == note:
                        current_ch[i] = (0, 0)
                        state_changed = True
                        break
            event_idx += 1

        if state_changed or duration_acc >= 32767:
            if duration_acc > 0:
                flag = 1
                dur = duration_acc & 0x7FFF
                n1, v1 = prev_ch[0]
                n2, v2 = prev_ch[1]
                n3, v3 = prev_ch[2]
                n4, v4 = prev_ch[3]
                
                bin_str = f"{flag:01b}{dur:015b}{n1:07b}{v1:05b}{n2:07b}{v2:05b}{n3:07b}{v3:05b}{n4:07b}{v4:05b}"
                raw_64bit_data.append(int(bin_str, 2))
                
            prev_ch = list(current_ch)
            duration_acc = 1
        else:
            duration_acc += 1

    raw_64bit_data.append(int("0000000000000000", 16))

    return raw_64bit_data

def save_hex(raw_64bit_data, hex_path):
    data_width_bits = 64
    bytes_per_word = data_width_bits // 8
    current_words = len(raw_64bit_data)
    
    target_words = 1
    while target_words < current_words:
        target_words *= 2
    if target_words < 16: target_words = 16
        
    aligned_data = raw_64bit_data + [0] * (target_words - current_words)
    hex_lines = []
    word_address = 0 
    
    for val in aligned_data:
        chunk = val.to_bytes(bytes_per_word, byteorder='big')
        len_byte = len(chunk)
        line = f":{len_byte:02X}{word_address:04X}00"
        
        data_hex = ""
        checksum_sum = len_byte + ((word_address >> 8) & 0xFF) + (word_address & 0xFF) + 0x00
        for b in chunk:
            data_hex += f"{b:02X}"
            checksum_sum += b
            
        line += data_hex
        checksum = (256 - (checksum_sum % 256)) % 256
        line += f"{checksum:02X}"
        hex_lines.append(line)
        word_address += 1 

    hex_lines.append(":00000001FF")

    with open(hex_path, 'w') as f:
        for line in hex_lines:
            f.write(line + '\n')

    print(f"[Quartus 13.1 HEX] 成功導出: {hex_path} | 深度: {target_words} words (需 {target_words * bytes_per_word} Bytes)")

def save_bin(raw_64bit_data, bin_path):
    with open(bin_path, 'wb') as f:
        for val in raw_64bit_data:
            f.write(val.to_bytes(8, byteorder='little'))
    print(f"成功導出二進位檔: {bin_path}")

def save_midi(files, name="BGM"):
    WORDS_PER_SONG = 512
    all_rom_data = []

    for file in midi_files:
        song_data = convert_midi_to_quartus_hex(file)
        
        # 防呆檢查：如果這首歌超大，超過 4096 行就印出警告並截斷
        if len(song_data) > WORDS_PER_SONG:
            print(f"警告：{file} 太長了！請增加 WORDS_PER_SONG。")
            song_data = song_data[:WORDS_PER_SONG]
            song_data[-1] = 0 # 確保最後一筆是 EOF (63 bit = 0)
            
        # 補零到剛好 4096 行
        padding_length = WORDS_PER_SONG - len(song_data)
        padded_song = song_data + [0] * padding_length
        
        all_rom_data.extend(padded_song)
    
    save_hex(all_rom_data, f"{name}.hex")
    save_bin(all_rom_data, f"{name}.bin")

if __name__ == "__main__":

    midi_files = ["Mutation.mid", "Sweden.mid", "Living Mice.mid", "Subwoofer Lullaby.mid"]
    save_midi(midi_files, "BGM")

    midi_files = ["Beginning 2.mid", "Haggstrom.mid", "Mice On Venus.mid", "Wet Hands.mid"]
    save_midi(midi_files, "BGM1")