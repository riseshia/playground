code = %q(puts("Shia,hobby:i"+32.chr+"don't"+32.chr+"know")).chars

puts <<END.gsub("#") { code.shift || "#" }
   ####
  ##  ##
  ##
   ####
      ##
  ##  ##
   ####

 #########
 #########
 #########
END
