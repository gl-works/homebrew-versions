require 'formula'

class Cassandra12 < Formula
  homepage 'http://cassandra.apache.org'
  url 'http://www.apache.org/dyn/closer.cgi?path=/cassandra/1.2.18/apache-cassandra-1.2.18-bin.tar.gz'
  sha1 '5ec4e457392dc23ad421d3237e933872ff2ec8cf'

  conflicts_with 'cassandra',
    :because => "cassandra12 and cassandra install the same binaries."

  def install
    (var+"lib/cassandra").mkpath
    (var+"log/cassandra").mkpath
    (etc+"cassandra").mkpath

    inreplace "conf/cassandra.yaml", "/var/lib/cassandra", "#{var}/lib/cassandra"
    inreplace "conf/log4j-server.properties", "/var/log/cassandra", "#{var}/log/cassandra"
    inreplace "conf/cassandra-env.sh", "/lib/", "/"

    inreplace "bin/cassandra.in.sh" do |s|
      s.gsub! "CASSANDRA_HOME=\"`dirname \"$0\"`/..\"", "CASSANDRA_HOME=\"#{prefix}\""
      # Store configs in etc, outside of keg
      s.gsub! "CASSANDRA_CONF=\"$CASSANDRA_HOME/conf\"", "CASSANDRA_CONF=\"#{etc}/cassandra\""
      # Jars installed to prefix, no longer in a lib folder
      s.gsub! "/lib/", "/"
    end

    rm Dir["bin/*.bat"]

    (etc+"cassandra").install Dir["conf/*"]
    prefix.install Dir["*.txt"] + Dir["{bin,interface,javadoc,pylib,lib/licenses}"]
    prefix.install Dir["lib/*.jar"]

    share.install [bin+'cassandra.in.sh', bin+'stop-server']
    inreplace Dir["#{bin}/cassandra*", "#{bin}/debug-cql",
                  "#{bin}/json2sstable", "#{bin}/nodetool",
                  "#{bin}/sstable*"],
      /`dirname "?\$0"?`\/cassandra.in.sh/,
      "#{share}/cassandra.in.sh"
  end

  def caveats; <<-EOS.undent
    If you plan to use the CQL shell (cqlsh), you will need the Python CQL library
    installed. Since Homebrew prefers using pip for Python packages, you can
    install that using:

      pip install cql
    EOS
  end

  def plist; <<-EOS.undent
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
            <string>#{opt_prefix}/bin/cassandra</string>
            <string>-f</string>
        </array>

        <key>RunAtLoad</key>
        <true/>

        <key>WorkingDirectory</key>
        <string>#{var}/lib/cassandra</string>
      </dict>
    </plist>
    EOS
  end
end
