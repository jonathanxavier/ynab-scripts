require 'ofx-parser'

TRANSACTIONS_TO_IGNORE = ["Aplic.em Papeis","Resg.mer.aberto","bx Automatica Aplicacoes","Resgate Mercado Aberto", "Resg.De Papeis","Bx Aut Poupanca","Trans.Aut.Ccdi"]

str = open(ARGV[0]).read

# to FIX the crappy file exported
str.gsub!("<DTASOF>00000000000000","<DTASOF>#{Date.today.to_s.gsub('-','')}100001")
str.gsub!("<DTASOF>00000000","<DTASOF>#{Date.today.to_s.gsub('-','')}")
str.gsub!("<DTSERVER>00000000000000","<DTSERVER>#{Date.today.to_s.gsub('-','')}100001")

ofx = OfxParser::OfxParser.parse(str)
account = ofx.accounts.first

csv = account.statement.transactions.map do |transaction|
  next if TRANSACTIONS_TO_IGNORE.include? transaction.memo
  date = transaction.date.strftime("%d/%m/%Y")
  if transaction.type == :DEBIT
    [date,transaction.memo,nil,(defined?(note) ? note : nil),transaction.amount.gsub("-",""),nil]
  else
    [date,transaction.memo,nil,(defined?(note) ? note : nil),nil,transaction.amount]
  end
end

csv_header = "Date,Payee,Category,Memo,Outflow,Inflow"
csv_filename = ARGV[0].split("/").last.gsub(".ofx",".csv")
File.open(csv_filename,"w+") do |f|
  f.write(csv_header + "\n")
  csv.compact.each{|i| f.write(i.join(",") + "\n")}
end
