class VshPhp71 < Formula
  desc "General-purpose scripting language"
  homepage "https://www.php.net/"
  url "https://www.php.net/distributions/php-7.1.33.tar.xz"
  sha256 "bd7c0a9bd5433289ee01fd440af3715309faf583f75832b64fe169c100d52968"
  revision 261

  bottle do
    root_url "https://github.com/valet-sh/homebrew-core/releases/download/bottles"
    sha256 big_sur: "93640350723a10f40d90e7950fa85a25a110bdc59e2c711e0a05ded6398d7116"
  end

  depends_on "pkg-config" => :build
  depends_on "apr"
  depends_on "apr-util"
  depends_on "aspell"
  depends_on "autoconf"
  depends_on "curl"
  depends_on "freetds"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "glib"
  depends_on "gmp"
  depends_on "vsh-icu4c"
  depends_on "krb5"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libpq"
  depends_on "libyaml"
  depends_on "pcre"
  depends_on "libtool"
  depends_on "mcrypt"
  depends_on "libzip"
  depends_on "openldap"
  depends_on "openssl@1.1"
  depends_on "sqlite"
  depends_on "tidy-html5"
  depends_on "unixodbc"
  depends_on "webp"
  depends_on "imagemagick"

  # PHP build system incorrectly links system libraries
  # see https://github.com/php/php-src/pull/3472
  patch :DATA

  resource "xdebug_module" do
    url "https://github.com/xdebug/xdebug/archive/2.9.8.tar.gz"
    sha256 "28f8de8e6491f51ac9f551a221275360458a01c7690c42b23b9a0d2e6429eff4"
  end

  resource "imagick_module" do
    url "https://github.com/Imagick/imagick/archive/3.4.4.tar.gz"
    sha256 "8204d228ecbe5f744d625c90364808616127471581227415bca18857af981369"
  end

  def install
    # Ensure that libxml2 will be detected correctly in older MacOS
    ENV["SDKROOT"] = MacOS.sdk_path if MacOS.version == :el_capitan || MacOS.version == :sierra

    # Work around configure issues with Xcode 12
    # See https://bugs.php.net/bug.php?id=80171
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration"

    # Workaround for https://bugs.php.net/80310
    ENV.append "CFLAGS", "-DU_DEFINE_FALSE_AND_TRUE=1"
    ENV.append "CXXFLAGS", "-DU_DEFINE_FALSE_AND_TRUE=1"

    # buildconf required due to system library linking bug patch
    system "./buildconf", "--force"

    inreplace "sapi/fpm/php-fpm.conf.in", ";daemonize = yes", "daemonize = no"

    # Required due to icu4c dependency
    ENV.cxx11

    config_path = etc/"#{name}"
    # Prevent system pear config from inhibiting pear install
    (config_path/"pear.conf").delete if (config_path/"pear.conf").exist?

    # Prevent homebrew from hardcoding path to sed shim in phpize script
    ENV["lt_cv_path_SED"] = "sed"

    # Each extension that is built on Mojave needs a direct reference to the
    # sdk path or it won't find the headers
    headers_path = "=#{MacOS.sdk_path_if_needed}/usr"

    ENV["EXTENSION_DIR"] = "#{prefix}/lib/#{name}/20160303"
    ENV["PHP_PEAR_PHP_BIN"] = "#{bin}/php#{bin_suffix}"

    args = %W[
      --prefix=#{prefix}
      --localstatedir=#{var}
      --sysconfdir=#{config_path}
      --libdir=#{prefix}/lib/#{name}
      --includedir=#{prefix}/include/#{name}
      --datadir=#{prefix}/share/#{name}
      --with-config-file-path=#{config_path}
      --with-config-file-scan-dir=#{config_path}/conf.d
      --program-suffix=#{bin_suffix}
      --with-pear=#{pkgshare}/pear
      --enable-bcmath
      --enable-calendar
      --enable-dba
      --enable-dtrace
      --enable-exif
      --enable-ftp
      --enable-fpm
      --enable-intl
      --enable-mbregex
      --enable-mbstring
      --enable-mysqlnd
      --enable-opcache-file
      --enable-pcntl
      --enable-phpdbg
      --enable-phpdbg-webhelper
      --enable-shmop
      --enable-soap
      --enable-sockets
      --enable-sysvmsg
      --enable-sysvsem
      --enable-sysvshm
      --enable-wddx
      --enable-zip
      --with-bz2#{headers_path}
      --with-curl=#{Formula["curl-openssl"].opt_prefix}
      --with-fpm-user=_www
      --with-fpm-group=_www
      --with-freetype-dir=#{Formula["freetype"].opt_prefix}
      --with-gd
      --with-gettext=#{Formula["gettext"].opt_prefix}
      --with-gmp=#{Formula["gmp"].opt_prefix}
      --with-iconv#{headers_path}
      --with-icu-dir=#{Formula["vsh-icu4c"].opt_prefix}
      --with-jpeg-dir=#{Formula["jpeg"].opt_prefix}
      --with-kerberos#{headers_path}
      --with-layout=GNU
      --with-ldap=#{Formula["openldap"].opt_prefix}
      --with-ldap-sasl#{headers_path}
      --with-libxml-dir#{headers_path}
      --with-libedit#{headers_path}
      --with-libzip
      --with-mcrypt=#{Formula["mcrypt"].opt_prefix}
      --with-mhash#{headers_path}
      --with-mysql-sock=/tmp/mysql.sock
      --with-mysqli=mysqlnd
      --with-ndbm#{headers_path}
      --with-openssl=#{Formula["openssl@1.1"].opt_prefix}
      --with-pdo-dblib=#{Formula["freetds"].opt_prefix}
      --with-pdo-mysql=mysqlnd
      --with-pdo-odbc=unixODBC,#{Formula["unixodbc"].opt_prefix}
      --with-pdo-pgsql=#{Formula["libpq"].opt_prefix}
      --with-pdo-sqlite=#{Formula["sqlite"].opt_prefix}
      --with-pgsql=#{Formula["libpq"].opt_prefix}
      --with-pic
      --with-png-dir=#{Formula["libpng"].opt_prefix}
      --with-pspell=#{Formula["aspell"].opt_prefix}
      --with-sqlite3=#{Formula["sqlite"].opt_prefix}
      --with-tidy=#{Formula["tidy-html5"].opt_prefix}
      --with-unixODBC=#{Formula["unixodbc"].opt_prefix}
      --with-webp-dir=#{Formula["webp"].opt_prefix}
      --with-xmlrpc
      --with-xsl#{headers_path}
      --with-zlib#{headers_path}
    ]

    system "./configure", *args
    system "make"
    system "make", "install"

    resource("xdebug_module").stage {
      system "#{bin}/phpize#{bin_suffix}"
      system "./configure", "--with-php-config=#{bin}/php-config#{bin_suffix}"
      system "make", "clean"
      system "make", "all"
      system "make", "install"
    }

    resource("imagick_module").stage {
      system "#{bin}/phpize#{bin_suffix}"
      system "./configure", "--with-php-config=#{bin}/php-config#{bin_suffix}"
      system "make", "clean"
      system "make", "all"
      system "make", "install"
    }

    # Use OpenSSL cert bundle
    inreplace "php.ini-development", /; ?openssl\.cafile=/,
      "openssl.cafile = \"#{etc}/openssl@1.1/cert.pem\""
    inreplace "php.ini-development", /; ?openssl\.capath=/,
      "openssl.capath = \"#{etc}/openssl@1.1/certs\""

    inreplace "sapi/fpm/www.conf" do |s|
      s.gsub!(/listen =.*/, "listen = /tmp/#{name}.sock")
    end

    config_files = {
      "php.ini-development"   => "php.ini",
      "sapi/fpm/php-fpm.conf" => "php-fpm.conf",
      "sapi/fpm/www.conf"     => "php-fpm.d/www.conf",
    }
    config_files.each_value do |dst|
      dst_default = config_path/"#{dst}.default"
      rm dst_default if dst_default.exist?
    end
    config_path.install config_files

    unless (var/"log/php-fpm#{bin_suffix}.log").exist?
      (var/"log").mkpath
      touch var/"log/php-fpm#{bin_suffix}.log"
    end

    mv "#{bin}/pecl", "#{bin}/pecl#{bin_suffix}"
    mv "#{bin}/pear", "#{bin}/pear#{bin_suffix}"
    mv "#{bin}/peardev", "#{bin}/peardev#{bin_suffix}"

    mv "#{bin}/phar.phar", "#{bin}/phar#{bin_suffix}.phar"
    rm_f "#{bin}/phar"
    ln_s "#{bin}/phar#{bin_suffix}.phar", "#{bin}/phar#{bin_suffix}"

    mv "#{man1}/phar.1", "#{man1}/phar#{bin_suffix}.1"
    mv "#{man1}/phar.phar.1", "#{man1}/phar#{bin_suffix}.phar.1"

  end

  def post_install

    # check if php extension dir (e.g. 20180731) exists and is not a symlink
    # only relevant when running "brew postinstall" manually
    if (lib/"#{name}/#{php_ext_dir}").exist? && !(lib/"#{name}/#{php_ext_dir}").symlink?
        unless (var/"#{name}/#{php_ext_dir}").exist?
            (var/"#{name}/#{php_ext_dir}").mkpath
        end

        Dir.glob(lib/"#{name}/#{php_ext_dir}/*") do |php_module|
            php_module_name = File.basename(php_module)
            mv "#{php_module}", var/"#{name}/#{php_ext_dir}/#{php_module_name}"
        end

        rm_r lib/"#{name}/#{php_ext_dir}"
        ln_s var/"#{name}/#{php_ext_dir}", lib/"#{name}/#{php_ext_dir}"
    end

    pear_prefix = pkgshare/"pear"

    puts "#{pear_prefix}"

    pear_files = %W[
      #{pear_prefix}/.depdblock
      #{pear_prefix}/.filemap
      #{pear_prefix}/.depdb
      #{pear_prefix}/.lock
    ]

    %W[
      #{pear_prefix}/.channels
      #{pear_prefix}/.channels/.alias
    ].each do |f|
      chmod 0755, f
      pear_files.concat(Dir["#{f}/*"])
    end

    chmod 0644, pear_files

    {
      "php_ini"  => etc/"#{name}/php.ini"
    }.each do |key, value|
      value.mkpath if /(?<!bin|man)_dir$/.match?(key)
      system bin/"pear#{bin_suffix}", "config-set", key, value, "system"
    end

    system bin/"pear#{bin_suffix}", "update-channels"

    %w[
      opcache
    ].each do |e|
      ext_config_path = etc/"#{name}/conf.d/ext-#{e}.ini"
      extension_type = (e == "opcache") ? "zend_extension" : "extension"
      if ext_config_path.exist?
        inreplace ext_config_path,
          /#{extension_type}=.*$/, "#{extension_type}=#{e}.so"
      else
        ext_config_path.write <<~EOS
          [#{e}]
          #{extension_type}="#{e}.so"
        EOS
      end
    end
  end

  def php_version
    version.to_s.split(".")[0..1].join(".")
  end

  def bin_suffix
    "#{php_version}"
  end

  def php_ext_dir
    extension_dir = Utils.popen_read("#{bin}/php-config#{bin_suffix} --extension-dir").chomp
    File.basename(extension_dir)
  end

  plist_options :manual => "php-fpm7.1"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>KeepAlive</key>
        <true/>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_sbin}/php-fpm#{bin_suffix}</string>
          <string>--nodaemonize</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{var}</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/#{name}.log</string>
      </dict>
    </plist>
  EOS
  end

  test do
    assert_match /^Zend OPcache$/, shell_output("#{bin}/php -i"),
      "Zend OPCache extension not loaded"
    # Test related to libxml2 and
    # https://github.com/Homebrew/homebrew-core/issues/28398
    assert_includes MachO::Tools.dylibs("#{bin}/php"),
      "#{Formula["libpq"].opt_lib}/libpq.5.dylib"
    system "#{sbin}/php-fpm#{bin_suffix}", "-t"
    system "#{bin}/phpdbg#{bin_suffix}", "-V"
    system "#{bin}/php-cgi#{bin_suffix}", "-m"
    # Prevent SNMP extension to be added
    assert_no_match /^snmp$/, shell_output("#{bin}/php -m"),
      "SNMP extension doesn't work reliably with Homebrew on High Sierra"
    begin
      require "socket"

      server = TCPServer.new(0)
      port = server.addr[1]
      server_fpm = TCPServer.new(0)
      port_fpm = server_fpm.addr[1]
      server.close
      server_fpm.close

      expected_output = /^Hello world!$/
      (testpath/"index.php").write <<~EOS
        <?php
        echo 'Hello world!' . PHP_EOL;
        var_dump(ldap_connect());
      EOS
      main_config = <<~EOS
        Listen #{port}
        ServerName localhost:#{port}
        DocumentRoot "#{testpath}"
        ErrorLog "#{testpath}/httpd-error.log"
        ServerRoot "#{Formula["httpd"].opt_prefix}"
        PidFile "#{testpath}/httpd.pid"
        LoadModule authz_core_module lib/httpd/modules/mod_authz_core.so
        LoadModule unixd_module lib/httpd/modules/mod_unixd.so
        LoadModule dir_module lib/httpd/modules/mod_dir.so
        DirectoryIndex index.php
      EOS

      (testpath/"httpd.conf").write <<~EOS
        #{main_config}
        LoadModule mpm_prefork_module lib/httpd/modules/mod_mpm_prefork.so
        LoadModule php7_module #{lib}/httpd/modules/libphp7.so
        <FilesMatch \\.(php|phar)$>
          SetHandler application/x-httpd-php
        </FilesMatch>
      EOS

      (testpath/"fpm.conf").write <<~EOS
        [global]
        daemonize=no
        [www]
        listen = 127.0.0.1:#{port_fpm}
        pm = dynamic
        pm.max_children = 5
        pm.start_servers = 2
        pm.min_spare_servers = 1
        pm.max_spare_servers = 3
      EOS

      (testpath/"httpd-fpm.conf").write <<~EOS
        #{main_config}
        LoadModule mpm_event_module lib/httpd/modules/mod_mpm_event.so
        LoadModule proxy_module lib/httpd/modules/mod_proxy.so
        LoadModule proxy_fcgi_module lib/httpd/modules/mod_proxy_fcgi.so
        <FilesMatch \\.(php|phar)$>
          SetHandler "proxy:fcgi://127.0.0.1:#{port_fpm}"
        </FilesMatch>
      EOS

      pid = fork do
        exec Formula["httpd"].opt_bin/"httpd", "-X", "-f", "#{testpath}/httpd.conf"
      end
      sleep 3

      assert_match expected_output, shell_output("curl -s 127.0.0.1:#{port}")

      Process.kill("TERM", pid)
      Process.wait(pid)

      fpm_pid = fork do
        exec sbin/"php-fpm#{bin_suffix}", "-y", "fpm.conf"
      end
      pid = fork do
        exec Formula["httpd"].opt_bin/"httpd", "-X", "-f", "#{testpath}/httpd-fpm.conf"
      end
      sleep 3

      assert_match expected_output, shell_output("curl -s 127.0.0.1:#{port}")
    ensure
      if pid
        Process.kill("TERM", pid)
        Process.wait(pid)
      end
      if fpm_pid
        Process.kill("TERM", fpm_pid)
        Process.wait(fpm_pid)
      end
    end
  end
end

__END__
diff --git a/acinclude.m4 b/acinclude.m4
index 168c465f8d..6c087d152f 100644
--- a/acinclude.m4
+++ b/acinclude.m4
@@ -441,7 +441,11 @@ dnl
 dnl Adds a path to linkpath/runpath (LDFLAGS)
 dnl
 AC_DEFUN([PHP_ADD_LIBPATH],[
-  if test "$1" != "/usr/$PHP_LIBDIR" && test "$1" != "/usr/lib"; then
+  case "$1" in
+  "/usr/$PHP_LIBDIR"|"/usr/lib"[)] ;;
+  /Library/Developer/CommandLineTools/SDKs/*/usr/lib[)] ;;
+  /Applications/Xcode*.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/*/usr/lib[)] ;;
+  *[)]
     PHP_EXPAND_PATH($1, ai_p)
     ifelse([$2],,[
       _PHP_ADD_LIBPATH_GLOBAL([$ai_p])
@@ -452,8 +456,8 @@ AC_DEFUN([PHP_ADD_LIBPATH],[
       else
         _PHP_ADD_LIBPATH_GLOBAL([$ai_p])
       fi
-    ])
-  fi
+    ]) ;;
+  esac
 ])

 dnl
@@ -487,7 +491,11 @@ dnl add an include path.
 dnl if before is 1, add in the beginning of INCLUDES.
 dnl
 AC_DEFUN([PHP_ADD_INCLUDE],[
-  if test "$1" != "/usr/include"; then
+  case "$1" in
+  "/usr/include"[)] ;;
+  /Library/Developer/CommandLineTools/SDKs/*/usr/include[)] ;;
+  /Applications/Xcode*.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/*/usr/include[)] ;;
+  *[)]
     PHP_EXPAND_PATH($1, ai_p)
     PHP_RUN_ONCE(INCLUDEPATH, $ai_p, [
       if test "$2"; then
@@ -495,8 +503,8 @@ AC_DEFUN([PHP_ADD_INCLUDE],[
       else
         INCLUDES="$INCLUDES -I$ai_p"
       fi
-    ])
-  fi
+    ]) ;;
+  esac
 ])

 dnl internal, don't use
@@ -2411,7 +2419,8 @@ AC_DEFUN([PHP_SETUP_ICONV], [
     fi

     if test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.a ||
-       test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.$SHLIB_SUFFIX_NAME
+       test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.$SHLIB_SUFFIX_NAME ||
+       test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.tbd
     then
       PHP_CHECK_LIBRARY($iconv_lib_name, libiconv, [
         found_iconv=yes
