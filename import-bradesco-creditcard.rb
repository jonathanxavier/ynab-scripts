require 'ofx-parser'

str = open(ARGV[0]).read
str.gsub!("<DTASOF>00000000000000","<DTASOF>#{Date.today.to_s.gsub('-','')}100001")
str.gsub!("<DTASOF>00000000","<DTASOF>#{Date.today.to_s.gsub('-','')}")
str.gsub!("<DTSERVER>00000000000000","<DTSERVER>#{Date.today.to_s.gsub('-','')}100001")

ofx = OfxParser::OfxParser.parse(str)
account = ofx.accounts.first

csv = account.statement.transactions.map do |transaction|
  date = transaction.date.strftime("%d/%m/%Y")
  if transaction.memo.match(/(.*)(\d{1,2}\/\d{1,2})/)
    transaction.memo = $1
    note = $2
    if transaction.date < Date.today - 30
      next_month = lambda do |date|
        (date > Date.today - 30) ? date : next_month.call(date.next_month)
      end
      d = next_month.call(transaction.date)
      d = d.prev_month if d > Date.today
      date = d.strftime("%d/%m/%Y")
    end
  end
  if transaction.type == :DEBIT
    [date,transaction.memo,nil,(defined?(note) ? note : nil),transaction.amount,nil]
  else
    [date,transaction.memo,nil,(defined?(note) ? note : nil),nil,transaction.amount]
  end
end

csv_header = "Date,Payee,Category,Memo,Outflow,Inflow"
csv_filename = ARGV[0].split("/").last.gsub(".ofx",".csv")
File.open(csv_filename,"w+") do |f|
  f.write(csv_header + "\n")
  csv.each{|i| f.write(i.join(",") + "\n")}
end
