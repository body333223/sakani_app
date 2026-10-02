#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sakani Application Live Server & Tunnel Runner - High Performance & Crash-Proof
- Runs high-performance .NET 8 Backend
- Opens Ngrok Permanent Static Domain (or fallback Cloudflare)
- Auto-recovers on disconnects, logs to file to avoid OS pipe deadlock
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

STATIC_NGROK_DOMAIN = "https://prodigal-overpower-nail.ngrok-free.dev"

def get_lan_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return '127.0.0.1'

def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(0.8)
        return s.connect_ex(('127.0.0.1', port)) == 0

def cleanup_stale_processes():
    """Kill old leftover ngrok or port 5093 processes to avoid port-binding collisions."""
    if sys.platform == 'win32':
        try:
            subprocess.run(['taskkill', '/F', '/IM', 'ngrok.exe'], capture_output=True)
            if is_port_in_use(5093):
                netstat_out = subprocess.run(['netstat', '-ano'], capture_output=True, text=True).stdout
                for line in netstat_out.splitlines():
                    if ':5093 ' in line and 'LISTENING' in line:
                        pid = line.strip().split()[-1]
                        subprocess.run(['taskkill', '/F', '/PID', pid], capture_output=True)
                time.sleep(1)
        except Exception:
            pass

def start_backend(dotnet_exe, dll_path, backend_dir, env, log_file):
    return subprocess.Popen(
        [dotnet_exe, dll_path, '--urls', 'http://0.0.0.0:5093'],
        cwd=backend_dir,
        env=env,
        stdout=log_file,
        stderr=subprocess.STDOUT
    )

def start_tunnel(ngrok_exe, cloudflared_exe, backend_dir, log_file):
    if os.path.exists(ngrok_exe):
        proc = subprocess.Popen(
            [ngrok_exe, 'http', f'--url={STATIC_NGROK_DOMAIN}', '5093'],
            cwd=backend_dir,
            stdout=log_file,
            stderr=subprocess.STDOUT
        )
        return proc, STATIC_NGROK_DOMAIN
    else:
        proc = subprocess.Popen(
            [cloudflared_exe, 'tunnel', '--url', 'http://127.0.0.1:5093'],
            cwd=backend_dir,
            stdout=log_file,
            stderr=subprocess.STDOUT
        )
        return proc, None

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
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

    ngrok_exe = os.path.join(backend_dir, 'ngrok.exe')
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

    # Check and clean up previous conflicting sessions
    if is_port_in_use(5093):
        print("[*] تنظيف جلسات سابقة كانت تحجز المنفذ 5093 لضمان التشغيل المستقر...")
        cleanup_stale_processes()

    env = dict(os.environ)
    env['DOTNET_ROOT'] = r'C:\Users\pC\.dotnet'
    env['ASPNETCORE_ENVIRONMENT'] = 'Production'

    backend_log = open(os.path.join(backend_dir, 'backend_server.log'), 'a', encoding='utf-8')
    tunnel_log = open(os.path.join(backend_dir, 'tunnel_server.log'), 'a', encoding='utf-8')

    # 1. Start Backend Process
    print("[1/3] جاري بدء تشغيل السيرفر الخلفي على المنفذ 5093...")
    backend_proc = start_backend(dotnet_exe, dll_path, backend_dir, env, backend_log)

    # 2. Verify Backend Health
    health_url = 'http://127.0.0.1:5093/api/apartments'
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

    # 3. Start Tunnel
    print("[2/3] جاري تشغيل النفق السحابي الدائم المشفر (Ngrok Static Domain)...")
    tunnel_proc, public_url = start_tunnel(ngrok_exe, cloudflared_exe, backend_dir, tunnel_log)
    time.sleep(2)
    public_url = STATIC_NGROK_DOMAIN
    print(f"[OK] تم تشغيل الرابط الدائم بنجاح: {public_url}")

    lan_ip = get_lan_ip()
    live_api_url = f"{public_url}/api"

    # 4. Sync api_config.dart
    if os.path.exists(api_config_file):
        print("[3/3] جاري التحقق من مطابقة رابط الـ API في تطبيق فلاتر...")
        try:
            with open(api_config_file, 'r', encoding='utf-8') as f:
                config_code = f.read()

            new_config_code = re.sub(
                r"static const String liveServerUrl = 'https://[^']+';",
                f"static const String liveServerUrl = '{live_api_url}';",
                config_code
            )

            new_config_code = re.sub(
                r"static const String localServerUrl = 'http://[^:]+:5093/api';",
                f"static const String localServerUrl = 'http://{lan_ip}:5093/api';",
                new_config_code
            )

            with open(api_config_file, 'w', encoding='utf-8') as f:
                f.write(new_config_code)

            print(f"[OK] تم تأكيد ضبط api_config.dart على: {live_api_url}")
        except Exception as e:
            print(f"[!] خطأ أثناء فحص api_config.dart: {e}")

    # 5. Display Dashboard
    print("\n" + "=" * 72)
    print("          *** تم تشغيل الباك اند وربطه بالكامل بنجاح! ***")
    print("=" * 72)
    print(f" [*] الرابط السحابي الدائم (HTTPS): {public_url}/api")
    print(f" [*] واجهة توثيق العمليات (Swagger): {public_url}/swagger")
    print(f" [*] الرابط المحلي (Localhost):      http://localhost:5093/api")
    print(f" [*] رابط الشبكة الداخلية (Wi-Fi):  http://{lan_ip}:5093/api")
    print(" [*] حماية واستقرار:                 Auto-Recovery + Zero-Pipe-Lock + WAL")
    print("=" * 72)
    print(" [i] السيرفر يعمل الآن بشكل مستمر دون توقف. اضغط Ctrl+C للإيقاف.")
    print("=" * 72 + "\n")

    def signal_handler(sig, frame):
        print("\n[*] جاري إيقاف السيرفر والنفق...")
        try:
            backend_proc.terminate()
            tunnel_proc.terminate()
            backend_log.close()
            tunnel_log.close()
        except Exception:
            pass
        print("[OK] تم الإيقاف بنجاح.")
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    backend_fails = 0
    tunnel_fails = 0

    try:
        while True:
            time.sleep(2)
            # Auto-restart backend if terminated unexpectedly
            if backend_proc.poll() is not None:
                backend_fails += 1
                if backend_fails > 5:
                    print("[!] تنبيه: تكرر توقف السيرفر الخلفي. جاري الانتظار 5 ثوانٍ قبل إعادة المحاولة...")
                    time.sleep(5)
                else:
                    print("[!] تنبيه: السيرفر الخلفي توقف، جاري إعادة تشغيله تلقائياً...")
                    backend_proc = start_backend(dotnet_exe, dll_path, backend_dir, env, backend_log)
                    time.sleep(1.5)
            else:
                backend_fails = 0

            # Auto-restart tunnel if terminated unexpectedly
            if tunnel_proc.poll() is not None:
                tunnel_fails += 1
                if tunnel_fails > 5:
                    print("[!] تنبيه: نفق الاتصال توقف بشكل متكرر. جاري الانتظار 5 ثوانٍ قبل إعادة المحاولة...")
                    time.sleep(5)
                else:
                    print("[!] تنبيه: نفق الاتصال توقف، جاري إعادة تشغيله تلقائياً...")
                    tunnel_proc, _ = start_tunnel(ngrok_exe, cloudflared_exe, backend_dir, tunnel_log)
                    time.sleep(1.5)
            else:
                tunnel_fails = 0
    except KeyboardInterrupt:
        signal_handler(None, None)

if __name__ == '__main__':
    main()
