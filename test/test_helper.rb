require 'helpers/mock_shell'

# Override the `shell` private method of the firewall to return the mock
# shell. The mock shell's purpose is to capture any system calls made and
# verify that they were received.
def stubbed_firewall(target)
  Class.new(target) do
    define_method(:shell) do
      MockShell
    end
  end
end
