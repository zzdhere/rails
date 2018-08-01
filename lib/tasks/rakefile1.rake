namespace :profit do
  task change_profit: :environment do
    require 'roo'
    file = "e:/profit.xlsx"
    a = []
    sql1 = "select profit_center_code from fmis_report_profit_centers"
    code = FmisReport::ProfitCenter.find_by_sql(sql1)
    code.each do |acc|
      a << acc['profit_center_code']
    end
    # loop do
      if File.exists?(file)
        xlsx = Roo::Spreadsheet.open(file, extension: :xlsx)
        sheet = xlsx.sheet(0)
        sheet.each do |row|
          a1 = []
          a1 << row[0].to_s
          unless (a1 - a).length == 0
            FmisReport::ProfitCenter.create profit_center_code: row[0],
                                            cost_center_code: row[1],
                                            exp_type: row[2],
                                            business_type: row[3],
                                            dept: row[4],
                                            group: row[5],
                                            commodity: row[6],
                                             status: row[7]
          end
        end
      end
    # end
    puts "Over"
  end
end