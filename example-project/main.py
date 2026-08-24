import sys
import platform

def main():
    print("=" * 45)
    print("  OpenCode Custom Ubuntu Sandbox Check")
    print("=" * 45)
    
    # Read distribution metadata (/etc/os-release)
    try:
        os_info = platform.freedesktop_os_release()
        distro = f"{os_info.get('NAME')} {os_info.get('VERSION')}"
    except Exception:
        distro = platform.system()

    print(f"OS Distribution : {distro}")
    print(f"Host Kernel     : {platform.release()}")
    print(f"Python Version  : {sys.version.split()[0]}")
    print(f"Executable      : {sys.executable}")
    print("=" * 45)

if __name__ == "__main__":
    main()
