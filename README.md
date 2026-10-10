# TunnelX

Experimental TCP tunneling project written in Go.

## Current status

- Local TCP forwarding tested on Android/Termux.
- Linux AMD64 and ARM64 binaries cross-compiled.
- Real VPS testing and performance benchmarks are pending.
- Not production-ready.

## Linux binaries

- tunnelx-linux-amd64: Linux x86_64 VPS
- tunnelx-linux-arm64: Linux ARM64 VPS

Check your VPS architecture with:

    uname -m

Typical results:
- x86_64: use AMD64
- aarch64: use ARM64

## Security

- Use a strong, unique token.
- Use a trusted TLS certificate matching the VPS hostname.
- Never share private keys or production tokens.
- Restrict the tunnel port with firewall rules.
- Do not expose services you do not own or have permission to access.

## Known limitations

- Automatic reconnect is not implemented.
- Real VPS-to-client testing is pending.
- Performance and stability benchmarks are pending.
- This is an experimental build, not suitable for production use.


لینک نصب اسان اسکریپت 
تین اسکریپت تازه ساخته شده و نیازمند حمایت شما عزیزان هستش

bash <(curl -Ls https://raw.githubusercontent.com/mojibakhshi8-cyber/TunnelX/main/install.sh)
