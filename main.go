package main

import (
	"crypto/subtle"
	"crypto/tls"
	"crypto/x509"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"time"
)

func main() {
	mode := flag.String("mode", "", "server or client")
	listen := flag.String("listen", "", "listen address")
	remote := flag.String("remote", "", "remote server address")
	target := flag.String("target", "", "server-side target address")
	token := flag.String("token", "", "shared secret")
	certFile := flag.String("cert", "", "server TLS certificate")
	keyFile := flag.String("key", "", "server TLS private key")
	caFile := flag.String("ca", "", "trusted server certificate PEM")
	serverName := flag.String("server-name", "", "expected TLS server name")
	flag.Parse()

	if *token == "" {
		log.Fatal("ERROR: -token is required")
	}

	switch *mode {
	case "server":
		if *listen == "" || *target == "" ||
			*certFile == "" || *keyFile == "" {
			log.Fatal("server requires -listen -target -cert -key")
		}

		cert, err := tls.LoadX509KeyPair(*certFile, *keyFile)
		if err != nil {
			log.Fatal("Load certificate: ", err)
		}

		cfg := &tls.Config{
			MinVersion:   tls.VersionTLS12,
			Certificates: []tls.Certificate{cert},
		}
		runServer(*listen, *target, *token, cfg)

	case "client":
		if *listen == "" || *remote == "" ||
			*caFile == "" || *serverName == "" {
			log.Fatal("client requires -listen -remote -ca -server-name")
		}

		pem, err := os.ReadFile(*caFile)
		if err != nil {
			log.Fatal("Read CA certificate: ", err)
		}

		roots := x509.NewCertPool()
		if !roots.AppendCertsFromPEM(pem) {
			log.Fatal("No valid certificates found in -ca file")
		}

		cfg := &tls.Config{
			MinVersion: tls.VersionTLS12,
			RootCAs:    roots,
			ServerName: *serverName,
		}
		runClient(*listen, *remote, *token, cfg)

	default:
		log.Fatal("Use -mode server or -mode client")
	}
}

func runServer(addr, target, token string, cfg *tls.Config) {
	ln, err := tls.Listen("tcp", addr, cfg)
	if err != nil {
		log.Fatal("TLS listen: ", err)
	}
	defer ln.Close()

	log.Println("TunnelX TLS server listening:", addr)

	for {
		conn, err := ln.Accept()
		if err != nil {
			log.Println("Accept error:", err)
			continue
		}
		go handleServer(conn, target, token)
	}
}

func handleServer(conn net.Conn, target, token string) {
	defer conn.Close()

	if err := conn.SetReadDeadline(time.Now().Add(10 * time.Second)); err != nil {
		return
	}

	auth := make([]byte, len(token))
	if _, err := io.ReadFull(conn, auth); err != nil {
		log.Println("Authentication read failed")
		return
	}

	if subtle.ConstantTimeCompare(auth, []byte(token)) != 1 {
		log.Println("Authentication failed")
		return
	}

	if err := conn.SetDeadline(time.Time{}); err != nil {
		return
	}

	dst, err := net.DialTimeout("tcp", target, 10*time.Second)
	if err != nil {
		log.Println("Target connection failed:", err)
		return
	}
	defer dst.Close()

	log.Println("Connected to target:", target)
	relay(conn, dst)
}

func runClient(addr, remote, token string, cfg *tls.Config) {
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		log.Fatal("Local listen: ", err)
	}
	defer ln.Close()

	log.Println("TunnelX client listening:", addr)

	for {
		conn, err := ln.Accept()
		if err != nil {
			log.Println("Accept error:", err)
			continue
		}
		go handleClient(conn, remote, token, cfg)
	}
}

func handleClient(local net.Conn, remote, token string, cfg *tls.Config) {
	defer local.Close()

	dialer := &net.Dialer{Timeout: 10 * time.Second}
	upstream, err := tls.DialWithDialer(dialer, "tcp", remote, cfg)
	if err != nil {
		log.Println("Secure remote connection failed:", err)
		return
	}
	defer upstream.Close()

	if _, err := io.WriteString(upstream, token); err != nil {
		log.Println("Authentication send failed")
		return
	}

	relay(local, upstream)
}

func relay(a, b net.Conn) {
	done := make(chan struct{}, 2)

	copyStream := func(dst, src net.Conn) {
		_, _ = io.Copy(dst, src)
		switch c := dst.(type) {
		case *net.TCPConn:
			_ = c.CloseWrite()
		case *tls.Conn:
			_ = c.CloseWrite()
		}
		done <- struct{}{}
	}

	go copyStream(a, b)
	go copyStream(b, a)

	<-done
	_ = a.SetDeadline(time.Now())
	_ = b.SetDeadline(time.Now())
	<-done
}

func checkAddress(addr string) error {
	if _, _, err := net.SplitHostPort(addr); err != nil {
		return fmt.Errorf("invalid address %q: %w", addr, err)
	}
	return nil
}
