import os
import subprocess
import getpass
import base64
import sys

def find_keytool():
    """Mencari executable keytool di sistem."""
    paths_to_check = [
        "keytool",
        r"C:\Program Files\Java\jdk-17\bin\keytool.exe",
        r"C:\Program Files\Java\jdk-11\bin\keytool.exe",
        r"C:\Program Files\Java\jre1.8.0_*\bin\keytool.exe",
        r"C:\Program Files\OpenJDK\*\bin\keytool.exe",
        r"C:\Program Files (x86)\Java\*\bin\keytool.exe"
    ]
    
    # Coba jalankan keytool (asumsi ada di PATH)
    try:
        subprocess.run(["keytool", "-help"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        return "keytool"
    except FileNotFoundError:
        pass
    except subprocess.CalledProcessError:
        pass
        
    print("Mencari path keytool...")
    
    # Gunakan where jika di Windows
    if os.name == 'nt':
        try:
            result = subprocess.run(["where", "keytool"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
            paths = result.stdout.strip().split('\n')
            if paths:
                return paths[0]
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
            
    # Cari di registry lokal default 
    import glob
    for p in paths_to_check:
        if p == "keytool": continue
        matches = glob.glob(p)
        if matches:
            return matches[-1] # Ambil yang terbaru jika ada multiple
            
    return None

def main():
    print("=" * 50)
    print("🚀 Android Keystore Generator Otomatis")
    print("=" * 50)
    
    # Direktori target
    android_dir = r"f:\val\iotfy-mobile\android"
    keystore_path = os.path.join(android_dir, "upload-keystore.jks")
    properties_path = os.path.join(android_dir, "key.properties")
    
    # Cek apakah direktori valid
    if not os.path.exists(android_dir):
        print(f"❌ Error: Direktori Android tidak ditemukan ({android_dir})")
        return
        
    # Memeriksa keytool   
    keytool_cmd = find_keytool()
    if not keytool_cmd:
        print("❌ Error: 'keytool' tidak ditemukan di sistem ini.")
        print("Pastikan Java SDK/JRE sudah terinstall dan ada di environment PATH.")
        return
        
    print(f"✅ Menggunakan: {keytool_cmd}")
    
    # Jika keystore sudah ada, beri opsi untuk menimpa
    if os.path.exists(keystore_path):
        resp = input(f"⚠️ Keystore '{keystore_path}' sudah ada. Timpa? (y/N): ")
        if resp.lower() != 'y':
            print("Dibatalkan.")
            return
        os.remove(keystore_path)
        
    # Input parameter
    print("\n📝 Masukkan Informasi Keystore:")
    
    alias = input("Key Alias [default: upload]: ").strip() or "upload"
    
    while True:
        password = getpass.getpass("Password Keystore (min 6 karakter): ")
        if len(password) >= 6:
            confirm = getpass.getpass("Konfirmasi Password: ")
            if password == confirm:
                break
            else:
                print("❌ Password tidak cocok. Coba lagi.")
        else:
            print("❌ Password terlalu pendek. Minimal 6 karakter.")
            
    # Opsi data dname (X.500 Distinguished Name)
    print("\nℹ️ Tekan Enter untuk menggunakan nilai default atau isi data baru")
    cn = input("Nama Depan & Belakang [default: Unknown]: ").strip() or "Unknown"
    ou = input("Unit Organisasi [default: Unknown]: ").strip() or "Unknown"
    o = input("Nama Organisasi [default: Unknown]: ").strip() or "Unknown"
    l = input("Kota/Lokalitas [default: Unknown]: ").strip() or "Unknown"
    st = input("Negara Bagian/Provinsi [default: Unknown]: ").strip() or "Unknown"
    c = input("Kode Negara (2 huruf, cnth: ID) [default: Unknown]: ").strip() or "Unknown"
    
    dname = f"CN={cn}, OU={ou}, O={o}, L={l}, ST={st}, C={c}"
    
    # Menjalankan perintah keytool
    print("\n⏳ Sedang membuat keystore. Mohon tunggu...")
    
    cmd = [
        keytool_cmd,
        "-genkeypair",
        "-v",
        "-keystore", keystore_path,
        "-storetype", "JKS",
        "-keyalg", "RSA",
        "-keysize", "2048",
        "-validity", "10000",
        "-alias", alias,
        "-dname", dname,
        "-storepass", password,
        "-keypass", password
    ]
    
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(f"✅ Keystore berhasil dibuat di:\n   {keystore_path}")
    except subprocess.CalledProcessError as e:
        print(f"❌ Gagal membuat keystore:\n{e.stderr.decode('utf-8', errors='ignore')}")
        return
        
    # Membuat key.properties
    try:
        with open(properties_path, "w") as f:
            f.write(f"storePassword={password}\n")
            f.write(f"keyPassword={password}\n")
            f.write(f"keyAlias={alias}\n")
            f.write(f"storeFile=upload-keystore.jks\n")
        print(f"✅ key.properties berhasil dibuat di:\n   {properties_path}")
    except Exception as e:
        print(f"❌ Gagal membuat key.properties: {e}")
        return
        
    # Menggenerate Base64 untuk GitHub Secrets
    print("\n" + "=" * 50)
    print("🔑 DATA UNTUK GITHUB SECRETS")
    print("Silakan copy & paste teks di bawah ini ke GitHub Settings > Secrets:")
    print("=" * 50)
    
    try:
        with open(keystore_path, "rb") as f:
            encoded = base64.b64encode(f.read()).decode("utf-8")
            
        print(f"\n1. Nama Secret : KEYSTORE_BASE64")
        print(f"   Value        :\n{encoded}\n")
        
        print(f"2. Nama Secret : KEY_ALIAS")
        print(f"   Value        : {alias}")
        
        print(f"3. Nama Secret : KEY_PASSWORD")
        print(f"   Value        : {repr(password).strip(repr(password)[0])} (sama dengan yg Anda isi tadi)")
        
        print(f"4. Nama Secret : STORE_PASSWORD")
        print(f"   Value        : {repr(password).strip(repr(password)[0])} (sama dengan yg Anda isi tadi)")
        
        print("\n\n✅ Selesai! Setelah memasukkan rahasia di atas ke GitHub, Anda bisa:")
        print("git add .")
        print('git commit -m "ci: Update keystore dan CI config"')
        print("git push origin main")
        
    except Exception as e:
        print(f"❌ Gagal membaca keystore untuk base64 encoding: {e}")

if __name__ == "__main__":
    main()
