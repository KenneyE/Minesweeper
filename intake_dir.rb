class Input
  begin
    system("stty raw -echo")
    str = STDIN.getc
  ensure
    system("stty -raw echo")
  end
  p str.chr
end