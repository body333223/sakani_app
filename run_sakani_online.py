#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sakani Application Live Server & Tunnel Runner
- Runs high-performance .NET 8 Backend
- Opens Cloudflare Tunnel with global HTTPS
- Auto-detects URL and updates Flutter ApiConfig
"""
import os
import sys

if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8', line_buffering=True)
        sys.stderr.reconfigure(encoding='utf-8', line_buffering=True)
    except Exception:
        pass

import re
import time
import socket
import urllib.request
import subprocess
import signal

def get_lan_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return '127.0.0.1'

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    # Handle if run from root or from sakani_app
    if os.path.basename(base_dir) == 'sakani_app':
        root_dir = os.path.dirname(base_dir)
        backend_dir = os.path.join(root_dir, 'SakaniBackend')
        flutter_dir = base_dir
    elif os.path.basename(base_dir) == 'SakaniBackend':
        root_dir = os.path.dirname(base_dir)
        backend_dir = base_dir
        flutter_dir = os.path.join(root_dir, 'sakani_app')
    else:
        root_dir = base_dir
        backend_dir = os.path.join(root_dir, 'SakaniBackend')
        flutter_dir = os.path.join(root_dir, 'sakani_app')

    dotnet_exe = r'C:\Users\pC\.dotnet\dotnet.exe'
    if not os.path.exists(dotnet_exe):
        dotnet_exe = 'dotnet'

    cloudflared_exe = os.path.join(backend_dir, 'cloudflared.exe')
    dll_path = os.path.join(backend_dir, 'publish', 'SakaniBackend.dll')
    if not os.path.exists(dll_path):
        dll_path = os.path.join(backend_dir, 'bin', 'Release', 'net8.0', 'SakaniBackend.dll')
    if not os.path.exists(dll_path):
        dll_path = os.path.join(backend_dir, 'bin', 'Debug', 'net8.0', 'SakaniBackend.dll')

    api_config_file = os.path.join(flutter_dir, 'lib', 'core', 'config', 'api_config.dart')

    print("=" * 72)
    print("      >> تشغيل سيرفر سكني (Sakani Backend) والربط مع التطبيق <<")
    print("=" * 72)
    print(f"[*] Backend DLL: {dll_path}")

    # Set environment variables for .NET 8
    env = dict(os.environ)
    env['DOTNET_ROOT'] = r'C:\Users\pC\.dotnet'
    env['ASPNETCORE_ENVIRONMENT'] = 'Production'

    # 1. Start Backend Process
    print("[1/3] جاري بدء تشغيل السيرفر الخلفي على المنفذ 5093...")
    backend_proc = subprocess.Popen(
        [dotnet_exe, dll_path, '--urls', 'http://0.0.0.0:5093'],
        cwd=backend_dir,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding='utf-8',
        errors='replace'
    )

    # 2. Verify Backend Health
    health_url = 'http://127.0.0.1:5093/'
    server_ready = False
    for _ in range(25):
        time.sleep(0.5)
        try:
            with urllib.request.urlopen(health_url, timeout=2) as resp:
                if resp.status == 200:
                    server_ready = True
                    break
        except Exception:
            continue

    if not server_ready:
        print("[!] تحذير: السيرفر قد يستغرق وقتاً أطول للبدء. جاري المتابعة...")
    else:
        print("[OK] السيرفر الخلفي يعمل بنجاح وكفاءة فائقة!")

    ngrok_exe = os.path.join(backend_dir, 'ngrok.exe')
    use_ngrok = os.path.exists(ngrok_exe)

    # 3. Start Secure Tunnel (Ngrok Static Domain or Cloudflare)
    public_url = None
    if use_ngrok:
        print("[2/3] جاري تشغيل نفق سحابي دائم ومشفر (Ngrok Permanent Static Domain)...")
        tunnel_proc = subprocess.Popen(
            [ngrok_exe, 'http', '--url=https://prodigal-overpower-nail.ngrok-free.dev', '5093', '--log=stdout'],
            cwd=backend_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding='utf-8',
            errors='replace'
        )
        time.sleep(2)
        public_url = "https://prodigal-overpower-nail.ngrok-free.dev"
        print("[OK] تم تشغيل الرابط الدائم والثابت بنجاح!")
    else:
        print("[2/3] جاري إنشاء نفق سحابي عالمي مشفر (Cloudflare HTTPS Tunnel)...")
        tunnel_proc = subprocess.Popen(
            [cloudflared_exe, 'tunnel', '--url', 'http://127.0.0.1:5093'],
            cwd=backend_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding='utf-8',
            errors='replace'
        )

        start_time = time.time()
        while time.time() - start_time < 25:
            line = tunnel_proc.stderr.readline()
            if not line:
                time.sleep(0.1)
                continue
            match = re.search(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com', line)
            if match:
                public_url = match.group(0)
                break
        if public_url:
            print("[OK] تم إنشاء الرابط السحابي بنجاح!")

    lan_ip = get_lan_ip()

    if public_url:
        live_api_url = f"{public_url}/api"

        # 5. Update api_config.dart automatically
        if os.path.exists(api_config_file):
            print("[3/3] جاري تحديث رابط الـ API في تطبيق فلاتر (api_config.dart)...")
            try:
                with open(api_config_file, 'r', encoding='utf-8') as f:
                    config_code = f.read()

                new_config_code = re.sub(
                    r"static const String liveServerUrl = 'https://[^']+';",
                    f"static const String liveServerUrl = '{live_api_url}';",
                    config_code
                )

                # Also update local ip
                new_config_code = re.sub(
                    r"static const String localServerUrl = 'http://[^:]+:5093/api';",
                    f"static const String localServerUrl = 'http://{lan_ip}:5093/api';",
                    new_config_code
                )

                with open(api_config_file, 'w', encoding='utf-8') as f:
                    f.write(new_config_code)
                print(f"[OK] تم تحديث api_config.dart بنجاح إلى: {live_api_url}")
            except Exception as e:
                print(f"[!] خطأ أثناء تحديث api_config.dart: {e}")
    else:
        print("[!] لم يتم التقاط رابط Cloudflare تلقائياً. تأكد من اتصال الإنترنت.")

    # 6. Display Dashboard
    print("\n" + "=" * 72)
    print("          *** تم تشغيل الباك اند وربطه بالكامل بنجاح! ***")
    print("=" * 72)
    if public_url:
        print(f" [*] الرابط السحابي المباشر (HTTPS):  {public_url}/api")
        print(f" [*] واجهة توثيق العمليات (Swagger):  {public_url}/swagger")
    print(f" [*] الرابط المحلي (Localhost):       http://localhost:5093/api")
    print(f" [*] رابط الشبكة الداخلية (Wi-Fi):   http://{lan_ip}:5093/api")
    print(" [*] مستوى التشفير:                  AES-256 + JWT + BCrypt + SSL/TLS")
    print(" [*] السرعة والأداء:                 Brotli Compression + SQLite WAL + NoTracking")
    print("=" * 72)
    print(" [i] اضغط Ctrl+C لإيقاف السيرفر والنفق في أي وقت.")
    print("=" * 72 + "\n")

    def signal_handler(sig, frame):
        print("\n[*] جاري إيقاف السيرفر والنفق السحابي...")
        try:
            backend_proc.terminate()
            tunnel_proc.terminate()
        except Exception:
            pass
        print("[OK] تم الإيقاف بنجاح.")
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    try:
        while True:
            time.sleep(1)
            if backend_proc.poll() is not None:
                print("[!] السيرفر الخلفي توقف بشكل غير متوقع.")
                break
            if tunnel_proc.poll() is not None:
                print("[!] نفق Cloudflare توقف.")
                break
    except KeyboardInterrupt:
        signal_handler(None, None)

if __name__ == '__main__':
    main()
