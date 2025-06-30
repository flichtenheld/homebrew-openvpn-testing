class Openvpn < Formula
  desc "SSL/TLS VPN implementing OSI layer 2 or 3 secure network extension"
  homepage "https://openvpn.net/community/"
  url "https://swupdate.openvpn.org/community/releases/openvpn-2.7_alpha2.tar.gz"
  mirror "https://build.openvpn.net/downloads/releases/openvpn-2.7_alpha2.tar.gz"
  sha256 "94c9efbe4a14e6374e02ffc409efad0e6e1f2961e9141f8021de3d88eeb309b2"
  license "GPL-2.0-only" => { with: "openvpn-openssl-exception" }

  livecheck do
    url "https://openvpn.net/community-downloads/"
    regex(/href=.*?openvpn[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  depends_on "pkgconf" => :build
  depends_on "lz4"
  depends_on "lzo"
  depends_on "openssl@3"
  depends_on "pkcs11-helper"

  on_linux do
    depends_on "libcap-ng"
    depends_on "libnl"
    depends_on "linux-pam"
    depends_on "net-tools"
  end

  patch :DATA

  def install
    system "./configure", "--disable-silent-rules",
                          "--with-crypto-library=openssl",
                          "--enable-pkcs11",
                          *std_configure_args
    inreplace "sample/sample-plugins/Makefile" do |s|
      if OS.mac?
        s.gsub! Superenv.shims_path/"pkg-config", Formula["pkgconf"].opt_bin/"pkg-config"
      else
        s.gsub! Superenv.shims_path/"ld", "ld"
      end
    end
    system "make", "install"

    inreplace "sample/sample-config-files/openvpn-startup.sh",
              "/etc/openvpn", etc/"openvpn"

    (doc/"samples").install Dir["sample/sample-*"]
    (etc/"openvpn").install doc/"samples/sample-config-files/client.conf"
    (etc/"openvpn").install doc/"samples/sample-config-files/server.conf"

    # We don't use mbedtls, so this file is unnecessary & somewhat confusing.
    rm doc/"README.mbedtls"
  end

  def post_install
    (var/"run/openvpn").mkpath
  end

  service do
    run [opt_sbin/"openvpn", "--config", etc/"openvpn/openvpn.conf"]
    keep_alive true
    require_root true
    working_dir etc/"openvpn"
  end

  test do
    system sbin/"openvpn", "--show-ciphers"
  end
end
__END__
From 1469428f47ada85350e07088e4037ec2bedda1c5 Mon Sep 17 00:00:00 2001
From: Frank Lichtenheld <frank@lichtenheld.com>
Date: Mon, 30 Jun 2025 16:08:30 +0200
Subject: [PATCH] packet_id: Fix build with --disable-debug

Broken since commit
bc62a9a02cb7365a678bcd3f2faf537a420cc5a0
"Add methods to read/write packet ids for epoch data"

Change-Id: I3bed9c7aafee8e62ddae14c0d3e21cf4c146a37c
Signed-off-by: Frank Lichtenheld <frank@lichtenheld.com>
---

diff --git a/src/openvpn/packet_id.c b/src/openvpn/packet_id.c
index c8dae32..76a81c6 100644
--- a/src/openvpn/packet_id.c
+++ b/src/openvpn/packet_id.c
@@ -673,6 +673,8 @@
     gc_free(&gc);
 }
 
+#endif /* ifdef ENABLE_DEBUG */
+
 uint16_t
 packet_id_read_epoch(struct packet_id_net *pin, struct buffer *buf)
 {
@@ -711,6 +713,3 @@
 
     return buf_write(buf, &net_id, sizeof(net_id));
 }
-
-
-#endif /* ifdef ENABLE_DEBUG */
