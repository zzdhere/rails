class FmisReport::ReportViewController < ApplicationController
  include FmisReport::ReportViewHelper
  RC_GROUP = /(R(\[([0-9\-]+)\])?C(\[([0-9\-]+)\])?)([^\[A-Z]|$)/

  def initialize
    @model_type = FmisReport::Report
    super
  end

  def list_reports
    @model_type = FmisReport::Report
    query do |records|
      records.each {|r| r['full_name'] = "#{r['name']} - #{r['title']}"}
    end
  end

  def report_config
    rpt = unless params[:name].blank?
            FmisReport::Report.find_by_name(params[:name])
          else
            FmisReport::Report.find(params[:id])
          end
    render_success_json report: rpt, company: Rails.application.config.company
  end

  def load_table
    months = params[:months]
    @model_type = FmisReport::ReportLine
    if params[:month_year].blank?
      lines = @model_type.find_by_sql "SELECT * FROM #{@model_type.table_name} WHERE report_id = #{params[:report_id]} ORDER BY number ASC, id ASC"
      render_success_json records: lines.collect {|l| l.attributes}
    else
      lines = @model_type.find_by_sql "SELECT * FROM #{@model_type.table_name} WHERE report_id = #{params[:report_id]} and created_at in (#{months}) ORDER BY number ASC, id ASC"
      render_success_json records: lines.collect {|l| l.attributes}
    end
  end

  def column_tree
    @model_type = FmisReport::ReportColumn

    #TODO: Add order
    sql = <<-SQL
      select A.*, GROUP_CONCAT(B.id) as children from fmis_report_report_columns as A
      left join fmis_report_report_columns as B on B.parent_id = A.id
      where A.report_id = #{params[:report_id]}
      group by A.id
    SQL

    cols = query(sql, false)
    ret = {
        text: 'ROOT',
        expanded: false,
        leaf: false,
        children: []
    }

    hash = {}

    cols.each do |_col|
      col = RecursiveOpenStruct.new _col
      hash[col.id] = {
          id: col.id,
          text: col.text,
          leaf: col.children.blank?,
          children: [],
          expanded: !col.children.blank?,
          position: col.position,
          width: col.width,
          align: col.align,
          is_items: col.is_items,
          is_quantity: col.is_quantity
      }
      # unless col.children.blank?
      #   hash[col.id].merge! ,
      # end

      if col.parent_id.blank?
        ret[:children] << hash[col.id]
        column_sort ret[:children]
      else
        hash[col.parent_id][:children] << hash[col.id]
        column_sort hash[col.parent_id][:children]
      end
    end

    render json: ret
  end

  def list_lines
    @model_type = FmisReport::ReportLine
    lines = @model_type.find_by_sql "SELECT * FROM #{@model_type.table_name} WHERE report_id = #{params[:report_id]} ORDER BY number ASC, id ASC"
    render_success_json records: lines.collect {|l| l.attributes}
  end

  def list_cell_values
    require_power :CELL_FORMULAS, silent: true
    report_id = params[:report_id]
    months = params[:months]
    cache = {}
    unless months.nil? or months.blank?
      # catch查询
      @docs = FmisReport::SapDocument.where('month_year in (?) ', months).all.load
      cache[:lines] = FmisReport::ReportLine.where('report_id=?', report_id).order('number asc, id asc').all
      cache[:accounts] = FmisReport::LedgerAccount.all
      cache[:profit_centers] = FmisReport::ProfitCenter.all
      cache[:docs] = @docs
      cache[:closing_balances] = FmisReport::PrevDoc.get_prev_balances months.last
      cache[:months] = months
      cache[:prev_period_roes] = FmisReport::SapMasterDataHelper::get_prev_roes months.last
      cache[:materials] = FmisReport::Material::all
      cache[:interco_revs] = FmisReport::SapCoPa::get_rev months
      cache[:interco_ars] = FmisReport::Interco::get_detail('AR', months)
      cache[:interco_aps] = FmisReport::Interco::get_detail('AP', months)
      cache[:interco_ar_cbs] = FmisReport::Interco::get_close_summary('AR', months.last)
      cache[:interco_ap_cbs] = FmisReport::Interco::get_close_summary('AP', months.last)
      cache[:fxes] = FmisReport::Fx.load_fxes months
      # nil处理
      cache[:closing_balances].each do |cb|
        cb.realtime_amount = cb.amount
      end
      cache[:interco_revs].each do |r|
        r.amount = r.income
      end
      cache[:interco_ars].each {|i| i.realtime_amount = i.amount}
      cache[:interco_aps].each {|i| i.realtime_amount = i.amount}
      cache[:interco_ar_cbs].each {|i| i.realtime_amount = i.amount}
      cache[:interco_ap_cbs].each {|i| i.realtime_amount = i.amount}
    end
    cols = FmisReport::ReportColumn.where('report_id=?', report_id).select('id').collect {|r| r.id}
    lines = FmisReport::ReportLine.where('report_id=?', report_id).select('id').collect {|r| r.id}
    sql = <<-SQL
    SELECT * FROM fmis_report_report_cells AS CELL
    LEFT JOIN fmis_report_report_columns AS COL ON COL.id = CELL.column_id
    LEFT JOIN fmis_report_report_lines AS LIN ON LIN.id = CELL.line_id
    WHERE CELL.column_id IN (#{cols.join(',')})
    AND CELL.line_id IN (#{lines.join(',')})
    ORDER BY CELL.column_id ASC, LIN.number ASC, CELL.id ASC
    SQL
    cells = FmisReport::ReportCell.find_by_sql(sql)
    # cells = FmisReport::ReportCell.where('column_id in (?) and line_id in (?)', cols, lines)
    hash = {}

    attrs = {}
    a = 0
    b = 0
    cells.each do |cell|
      hash[cell.line_id] = {} if hash[cell.line_id].nil?
      hash[cell.line_id][cell.column_id] = cell
      hash[cell.line_id]["c_#{cell.column_id}"] = cell.attributes #cell.value_def
      attrs[cell.line_id] = {} if attrs[cell.line_id].nil?
      attrs[cell.line_id][cell.column_id] = cell.attributes
      value_def = cell['value_def']

      # 结果判断
      if value_def.starts_with? 'TEXT#'
        hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = value_def.gsub(/^TEXT\#/, '')
      elsif value_def.eql? 'ROW#'
        hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = a + 1
        a = a + 1
      elsif value_def.eql? 'COL#'
        hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = b + 1
        b = b + 1
      elsif value_def.starts_with? '='
      else
        if value_def.downcase.include? 'select' or value_def.downcase.include? 'each'
          unless months.nil? or months.blank?
            l = lambda {|cache, line_id, column_id|
              eval(value_def)
            }
            ret = l.call(cache, cell.attributes['line_id'], cell.attributes['column_id'])
            # 计算"
            if ret.class == String and ret.starts_with? '=' and not ret.include? 'R[' and not ret.include? 'C[' and not ret.include? 'ROUND'
              rc = eval(ret.gsub(/=|$/, ' '))
              hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = change_str(rc.to_f.round(2))
            elsif ret.class == Float
              hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = change_str(ret.to_f.round(2))
            elsif ret.class == String and ret.include? "ROUND"
              value_def = ret.gsub(/=/, "")
              round_val = value_def.split(/^ROUND\(/)[1].split(",")[0]
              round_num = value_def.split(/^ROUND\(/)[1].split(",")[1].gsub(")", "")
              hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = change_str(eval(round_val).round(round_num.to_i))
              # elsif ret.class == String and ret.start_with? "IF"
              #   logger.info ret
            elsif ret.class == String and ret.include? "N("
              ret = ret.gsub(/N\(.*/, "0.0")
              res = mix_cells(cache, cell, ret)
              hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = res
            elsif ret.class == String and ret.starts_with? '=' and /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(ret)
              # ret=R[1]C+123
              res = mix_cells(cache, cell, ret)
              hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = res
            else
              if ret.to_f == 0.0
                ret = 0.0
                hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = change_str(ret.to_f.round(2))
              else
                hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = change_str(ret.to_f.round(2))
              end
            end
          end
        elsif value_def.start_with? '#'
          unless months.nil? or months.blank?
            l = lambda {|cache, line_id, column_id|
              eval(value_def)
            }
            ret = l.call(cache, cell.attributes['line_id'], cell.attributes['column_id'])
            hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = ret.gsub(/=/, "")
          end
        end
      end
    end
    cells.each do |cell|
      value_def = cell['value_def']
      unless months.nil? or months.blank?
        if value_def.starts_with? '='
          vd = value_def.gsub(/=/, "")
          if vd.class == String and not vd.include? "["
            hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = change_str(eval(vd).round(2))
          elsif vd == "0.0"
            hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = 0.0
          elsif vd.class == String and vd.include? "SUM(" and vd.include? "+" or vd.match(/-[A-Z]/) and not vd.include? "IF"
            res_sum = value_def.scan(/SUM\(.*\)/)
            va_value = []
            vaz = []
            res_sum.each do |rv|
              cell.value_def = "=" + rv
              va_value = extract_cell(cell)
            end
            va_value.each do |v|
              vaz << sum_compute(hash, cache, v)
            end
            # SUM()
            vaz_value = []
            vaz_value << eval(vaz.join("+"))
            cell.value_def = value_def
            vaz_value.each_with_index do |z, index|
              res_sum.each_with_index do |v, index1|
                if index == index1
                  cell.value_def.gsub!(v, "#{z}")
                end
              end
            end
            vf = cell.value_def
            vaa = []
            vab = []
            vax = cell.value_def.scan(/(R(\[([0-9\-]+)\])?C(\[([0-9\-]+)\])?)([^\[A-Z]|$)/).map {|g| g[0]}
            vax.each do |s|
              cell.value_def = s
              vaa << extract_cell(cell)
            end
            vaa.each do |v|
              vab << sum_compute(hash, cache, v)
            end
            cell.value_def = vf
            vab.each_with_index do |z, index|
              vax.each_with_index do |v, index1|
                if index == index1
                  cell.value_def.gsub!(v, "#{z}")
                end
              end
            end
            hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = change_str(eval("#{cell.value_def.gsub(/=/, "")}").to_f.round(2))
          elsif vd.include? 'IF'
            # IF(RC[-2]>RC[1],RC[-2]-RC[1],0)
            data_val = if_compute(cache, cell, vd)
            hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = data_val
          elsif vd.include? 'ROUND'
            data_val = round_compute(cache, cell, vd)
            hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = data_val
          else
            cell_value = extract_cell(cell)
            hash[cell.line_id]["c_#{cell.column_id}"]['value_def'] = parse_value(hash, cache, cell_value, value_def)
          end
        end
      end
    end
    render_success_json values: hash, cells: attrs
  end

  private
  def column_sort(list)
    list.sort! do |x, y|
      x[:position] <=> y[:position]
    end
  end

end
