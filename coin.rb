require 'formula'

class Coin < Formula
  homepage 'https://bitbucket.org/Coin3D/coin/wiki/Home'
  url 'https://bitbucket.org/Coin3D/coin/downloads/Coin-3.1.3.tar.gz'
  sha1 '8e9f05628461963623686d3ec53102214e233dd1'

  option "without-soqt", "Build without SoQt"

  if build.with? "soqt"
    depends_on "pkg-config" => :build
    depends_on "qt"
  end

  option "without-framework", "Build without creating Framework"

  resource "soqt" do
    url "https://bitbucket.org/Coin3D/coin/downloads/SoQt-1.5.0.tar.gz"
    sha1 "c64f00f8c219b69f10ddfffe6294fb02be73dd20"
  end

  # https://bitbucket.org/Coin3D/coin/pull-request/3/missing-include/diff
  patch do
    url "https://bitbucket.org/cbuehler/coin/commits/e146a6a93a6b807c28c3d73b3baba80fa41bc5f6/raw"
    sha1 "0afaabc6582e6bbf1d5f3ccfed982f846fef18a6"
  end
 
  # https://bitbucket.org/Coin3D/coin/issue/23/xcode-clang-error-compiling-freetypecpp
  # Fixes freetype.cpp build issue
  patch :p0 do
    url "https://bitbucket.org/Coin3D/coin/issue-attachment/23/Coin3D/coin/1351441783.52/23/fix-weird-error.diff"
    sha1 "1f870df1b845d0be884afaf1505d240b1374a599"
  end

  def install
    # https://bitbucket.org/Coin3D/coin/issue/47 (fix misspelled test flag)
    inreplace "configure", '-fno-for-scoping', '-fno-for-scope'

    # https://bitbucket.org/Coin3D/coin/issue/45 (suppress math-undefs)
    # http://ftp.netbsd.org/pub/pkgsrc/current/pkgsrc/graphics/Coin/patches/patch-include_Inventor_C_base_math-undefs.h
    inreplace "include/Inventor/C/base/math-undefs.h", "#ifndef COIN_MATH_UNDEFS_H", "#if false"

    if build.without? "framework"
      system "./configure", "--disable-debug", "--disable-dependency-tracking",
                            "--prefix=#{prefix}",
                            "--without-framework"
    else 
      system "./configure", "--disable-debug", "--disable-dependency-tracking",
                            "--prefix=#{prefix}",
                            "--with-framework-prefix=#{frameworks}"
    end

    system "make install"

    if build.with? "soqt"
      resource("soqt").stage do
        ENV.deparallelize

        # https://bitbucket.org/Coin3D/coin/issue/40#comment-7888751
        inreplace "configure", /^(LIBS=\$sim_ac_uniqued_list)$/, "# \\1"

        if build.without? "framework"
          system "./configure", "--disable-debug",
            "--disable-dependency-tracking",
            "--without-framework",
            "--prefix=#{prefix}"
        else
          system "./configure", "--disable-debug",
            "--disable-dependency-tracking",
            "--with-framework-prefix=#{frameworks}",
            "--prefix=#{prefix}"
        end

        system "make", "install"
      end
    end
  end
end
