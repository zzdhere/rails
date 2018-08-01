module FmisReport::ReportViewHelper
  def extract_cell(cell)
    if cell.class == Array
      return cell
    end
    if cell.value_def.start_with? '='
      v = cell.value_def.gsub(/=/, "").gsub("\n", "")
      if v.start_with? "SUM"
        if v.include? ":" and v.include? ","
          r = v.gsub(/SUM|\(|\)/, "").split(",")
          y = sum_mixvalues(cell, r)
          return y
        else
          r = v.gsub(/SUM|\(|\)/, "").split(":")
          r1 = /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(r[0])
          r2 = /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(r[1])
          attrs = []
          unless r1.nil? and r2.nil?
            if r1.nil?
              y = extract_values(cell, r2)
              return y
            elsif r2.nil?
              y = extract_values(cell, r1)
              return y
            else
              attrs << r1
              attrs << r2
              y = sum_values(cell, attrs)
              return y
            end
          end
        end
      elsif v.start_with? "R"
        if v.include? "+" or v.match(/-[A-Z]/)
          r = v.scan(/(R(\[([0-9\-]+)\])?C(\[([0-9\-]+)\])?)([^\[A-Z]|$)/).map {|g| g[0]}
          r_len = r.length - 1
          gather = []
          for i in 0..r_len do
            c = /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(r[i])
            gather << c
            if i == r_len
              x = extract_mixvalues(cell, gather)
            end
          end
          return x
        elsif /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(v)
          r = /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(v)
          zz = extract_values(cell, r)
          return zz
        end
      end
    elsif /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(cell.value_def)
      r = /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(cell.value_def)
      zz = extract_values(cell, r)
      return zz
    else
      return cell
    end

  end

  def sum_mixvalues(cell, r)
    value_gather = []
    r.each do |ra|
      if not ra.match(/\:/)
        ac = sum_values(cell, ra)
        value_gather << ac
      else
        r_match = []
        rb = ra.split(":")
        r1 = /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(rb[0])
        r2 = /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(rb[1])
        r_match << r1
        r_match << r2
        row = 0
        column = 0
        row = r_match[0][1].to_i unless r_match[0][1].blank?
        column = r_match[0][2].to_i unless r_match[0][2].blank?
        _column = FmisReport::ReportColumn.find(cell.column_id)
        _line = FmisReport::ReportLine.find(cell.line_id)
        unless column.eql? 0
          len1 = r_match[1][2].to_i - r_match[0][2].to_i
          report = FmisReport::Report.find(_column.report_id)
          columns = _flatten_column(report)
          offset = 0
          columns.each_with_index do |__column, index|
            if __column.eql? cell.column_id
              offset = index
              break
            end
          end
          column = column + offset
          if len1 < 0
            for j in len1..0 do
              begin_column_id = columns[column + j]
              value_gather << [begin_column_id, _line[:id]]
            end
          else
            for j in 0..len1 do
              begin_column_id = columns[column + j]
              value_gather << [begin_column_id, _line[:id]]
            end
          end
        end
        unless row.eql? 0
          len2 = r_match[1][1].to_i - r_match[0][1].to_i
          report = FmisReport::Report.find(_column.report_id)
          lines = FmisReport::ReportLine.where(report_id: report.id).order('number asc, id asc')
          offset = 0
          lines.each_with_index do |__line, index|
            if __line[:id].eql? _line.id
              offset = index
              break
            end
          end
          row = offset + row
          if len2 < 0
            for j in len2..0 do
              begin_line_id = lines[row + j][:id]
              value_gather << [_column[:id], begin_line_id]
            end
          else
            for j in 0..len2 do
              begin_line_id = lines[row + j][:id]
              value_gather << [_column[:id], begin_line_id]
            end
          end
        end
      end
    end
    return extract_cell(value_gather)
  end

  def sum_values(cell, r)
    value_gather = []
    for i in 0..r.length - 1
      row = 0
      column = 0
      row = r[i][1].to_i unless r[i][1].blank?
      column = r[i][2].to_i unless r[i][2].blank?
      _column = FmisReport::ReportColumn.find(cell.column_id)
      _line = FmisReport::ReportLine.find(cell.line_id)
      unless column.eql? 0
        if r[1][2].to_i > r[0][2].to_i
          len1 = r[1][2].to_i - r[0][2].to_i
        else
          len1 = r[0][2].to_i - r[1][2].to_i
        end
        report = FmisReport::Report.find(_column.report_id)
        columns = _flatten_column(report)
        offset = 0
        columns.each_with_index do |__column, index|
          if __column.eql? cell.column_id
            offset = index
            break
          end
        end
        column = column + offset
        for j in 0..len1 do
          begin_column_id = columns[column + j]
          value_gather << [begin_column_id, _line[:id]]
        end
        return extract_cell(value_gather)
      end
      unless row.eql? 0
        if r[1][1].to_i > r[0][1].to_i
          len2 = r[1][1].to_i - r[0][1].to_i
        else
          len2 = r[0][1].to_i - r[1][1].to_i
        end
        report = FmisReport::Report.find(_column.report_id)
        lines = FmisReport::ReportLine.where(report_id: report.id).order('number asc, id asc')
        offset = 0
        lines.each_with_index do |__line, index|
          if __line[:id].eql? _line.id
            offset = index
            break
          end
        end
        row = offset + row
        for j in 0..len2 do
          begin_line_id = lines[row + j][:id]
          value_gather << [_column[:id], begin_line_id]
        end
        return extract_cell(value_gather)
      end
    end
    value_gather
  end

  def extract_mixvalues(cell, r)
    value_gather = []
    r.each do |rg|
      row = 0
      column = 0
      row = rg[1].to_i unless rg[1].blank?
      column = rg[2].to_i unless rg[2].blank?
      report = nil
      _column = FmisReport::ReportColumn.find(cell.column_id)
      _line = FmisReport::ReportLine.find(cell.line_id)
      unless column.eql? 0
        report = FmisReport::Report.find(_column.report_id)
        columns = _flatten_column(report)
        offset = 0
        columns.each_with_index do |__column, index|
          if __column.eql? cell.column_id
            offset = index
            break
          end
        end
        column = column + offset
        column_id = columns[column]
        value_gather << [column_id, _line[:id]]
      end
      _line = FmisReport::ReportLine.find(cell.line_id)
      unless row.eql? 0
        report = FmisReport::Report.find(_column.report_id)
        lines = FmisReport::ReportLine.where(report_id: report.id).order('number asc, id asc')
        offset = 0
        lines.each_with_index do |__line, index|
          if __line[:id].eql? _line.id
            offset = index
            break
          end
        end
        row = offset + row
        line_id = lines[row][:id]
        value_gather << [_column[:id], line_id]
      end
    end
    return extract_cell(value_gather)
  end

  def extract_values(cell, r)
    row = 0
    column = 0
    row = r[1].to_i unless r[1].blank?
    column = r[2].to_i unless r[2].blank?
    report = nil
    _column = FmisReport::ReportColumn.find(cell.column_id)
    _line = FmisReport::ReportLine.find(cell.line_id)
    if not column.eql? 0 and not row.eql? 0
      report = FmisReport::Report.find(_column.report_id)
      columns = _flatten_column(report)
      offset = 0
      columns.each_with_index do |__column, index|
        if __column.eql? cell.column_id
          offset = index
          break
        end
      end
      column = column + offset
      new_column = columns[column]
      lines = FmisReport::ReportLine.where(report_id: report.id).order('number asc, id asc')
      skew = 0
      lines.each_with_index do |__line, index|
        if __line[:id].eql? _line.id
          skew = index
          break
        end
      end
      row = skew + row
      new_line = lines[row]
      attr = []
      attr << new_column
      attr << new_line[:id]
      return extract_cell(attr)
    else
      unless column.eql? 0
        report = FmisReport::Report.find(_column.report_id)
        columns = _flatten_column(report)
        offset = 0
        columns.each_with_index do |__column, index|
          if __column.eql? cell.column_id
            offset = index
            break
          end
        end
        column = column + offset
        _column = columns[column]
      end
      unless row.eql? 0
        report = FmisReport::Report.find(_column.report_id)
        lines = FmisReport::ReportLine.where(report_id: report.id).order('number asc, id asc')
        offset = 0
        lines.each_with_index do |__line, index|
          if __line[:id].eql? _line.id
            offset = index
            break
          end
        end
        row = offset + row
        _line = lines[row]
        _column = _column[:id]
      end
      attr = []
      attr << _column
      attr << _line[:id]
      return extract_cell(attr)
    end
  end

  def parse_cell(cache, cell_value, value_def)
    data = []
    val = FmisReport::ReportCell.where(column_id: cell_value[0][0], line_id: cell_value[0][1]).take
    logger.info value_def
    if val.nil?
      data = 0.0
    else
      if val.value_def.start_with? '='
        vac = val.value_def.gsub(/=/, "")
        vac_split = vac.scan(/(R(\[([0-9\-]+)\])?C(\[([0-9\-]+)\])?)([^\[A-Z]|$)/).map {|g| g[0]}
        # +-混合
        if vac.include? "+" or vac.match(/-[A-Z]/) and not vac.include? "IF"
          ac = operatcell(cache, val, vac)
          asc = []
          ac.each_with_index do |z, index|
            vac_split.each_with_index do |v, index1|
              if index == index1
                asc = vac.gsub!(v, "#{z}")
              end
            end
          end
          data = eval(asc).to_f.round(2)
        elsif vac.include? "ROUND"
          data = round_compute(cache, val, vac)
        elsif vac.include? "IF"
          data = if_compute(cache, val, vac)
        elsif vac.starts_with? "SUM"
          data_val = []
          cell_value.each do |ce|
            unless ce.length == 0
              aq = cell_compute(cache, ce)
              if aq.nil?
                data = 0.0
              else
                aq.flatten.each do |val|
                  unless val.class == Array
                    if val.class == Float
                      data_val << val
                    elsif val == 0
                      data_val << 0.0
                    else
                      l = lambda {|cache, line_id, column_id|
                        eval(val.value_def)
                      }
                      asde = l.call(cache, val['line_id'], val['column_id'])
                      if asde.class == String
                        data_val << eval(asde.gsub(/=/, ""))
                      else
                        data_val << asde.to_f
                      end
                    end
                  end
                end
                data = eval(data_val.join("+")).to_f
              end
            end
          end
          # R[1]C
        elsif /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(vac) and not vac.include? "ROUND" and not vac.starts_with? "IF"
          count_value = cell_verify(cache, cell_value[0])
          l = lambda {|cache, line_id, column_id|
            eval(count_value.value_def)
          }
          asre = l.call(cache, count_value['line_id'], count_value['column_id'])
          if asre.class == String
            data = eval(asre.gsub(/=/, ""))
          else
            data = asre.to_f
          end
        end
      else
        l = lambda {|cache, line_id, column_id|
          eval(val.value_def)
        }
        val_sing = l.call(cache, val['line_id'], val['column_id'])
        if val_sing.class == String
          data = eval(val_sing.gsub(/=/, ""))
        else
          data = val_sing.to_f
        end
      end
    end
    data
  end

  def operatcell(cache, cell_value, value_def)
    val_gather = []
    cv = extract_cell(cell_value)
    cv.each do |c|
      if c.nil?
        val_gather << 0.0
      else
        value = cell_compute(cache, c)
        if value.nil?
          val_gather << 0.0
        elsif value.class == Array
          if value.length == 0
            val_gather << 0.0
          else
            value_fl = value.flatten
            res = []
            value_fl.each do |va|
              if va.class == Float
                res << va
              else
                l = lambda {|cache, line_id, column_id|
                  eval(va.value_def)
                }
                asde = l.call(cache, va['line_id'], va['column_id'])
                if asde.class == String
                  res << eval(asde.gsub(/=/, ""))
                else
                  res << asde.to_f
                end
              end
            end
            val_gather << eval(res.join("+"))
          end
        else
          if value.class == Float
            val_gather << value
          else
            l = lambda {|cache, line_id, column_id|
              eval(value.value_def)
            }
            asde = l.call(cache, value['line_id'], value['column_id'])
            if asde.class == String
              val_gather << eval(asde.gsub(/=/, ""))
            else
              val_gather << asde.to_f
            end
          end
        end
      end
    end
    val_gather
  end

  def cell_compute(cache, cell_value)
    sum_gather = []
    if cell_value[1].class == Array
      cell_value.each do |c|
        cv = FmisReport::ReportCell.where(column_id: c[0], line_id: c[1]).take
        unless cv.nil?
          if cv.value_def.starts_with? "="
            if cv.value_def.gsub(/=/, "").starts_with? "SUM"
              c = extract_cell(cv)
              if c.length > 1
                c.each do |cc|
                  co = FmisReport::ReportCell.where(column_id: cc[0], line_id: cc[1]).take
                  if co.nil?
                    acc = 0
                  elsif co.value_def.starts_with? "="
                    ac = extract_cell(co)
                    acc = FmisReport::ReportCell.where(column_id: ac[0], line_id: ac[1]).take
                  end
                  sum_gather = acc
                end
              end
            elsif cv.value_def.include? "+" or cv.value_def.match(/-[A-Z]/)
              mix = operatcell(cache, cell_value, cv.value_def)
              acc = FmisReport::ReportCell.where(column_id: mix[0], line_id: mix[1]).take
              sum_gather = acc
            elsif cv.value_def == "0"
              sum_gather = cv.value_def.to_f
            elsif cv.value_def.include? "ROUND"
              logger.info cv.value_def
            elsif cv.value_def.starts_with? "IF"
              logger.info cv.value_def
            else
              ec = extract_cell(cv)
              if ec.nil?
                a_value = 0
              else
                column_id = ec[0]
                line_id = ec[1]
                if cv[line_id]["c_#{column_id}"].nil?
                  a_value = 0
                else
                  a_value = FmisReport::ReportCell.where(column_id: column_id, line_id: line_id).take
                end
              end
              sum_gather = a_value
            end
          elsif cv.value_def.include? "select"
            sum_gather = FmisReport::ReportCell.where(column_id: cv.column_id, line_id: cv.line_id).take
          else
            sum_gather = c
          end
        end
      end
    else
      # [1,0]
      res = cell_verify(cache, cell_value)
      if res.nil?
        sum_gather = 0
      else
        if res.class == Float
          sum_gather = cell_verify(cache, cell_value)
        elsif res == 0
          sum_gather = res.to_f
        else
          sum_gather = res
        end
      end
    end
    sum_gather
  end

  def cell_verify(cache, cell_value)
    column_id = cell_value[0]
    line_id = cell_value[1]
    cv = FmisReport::ReportCell.where(column_id: column_id, line_id: line_id).take
    count = []
    unless cv.nil?
      vl = cv['value_def']
      if vl.nil?
      elsif vl == 0.0
      elsif vl == 0
      else
        if vl.starts_with? "="
          unless cv.nil?
            if cv['value_def'].nil?
              count = 0
            else
              ress = cv['value_def'].gsub(/=/, "")
              if ress.starts_with? "SUM"
                ae = extract_cell(cv)
                ac = []
                ae.each do |e|
                  if e.length > 1
                    ac << cell_compute(cache, e)
                  end
                end
                count = ac
              elsif ress.start_with? "ROUND"
              elsif ress.start_with? "IF"
                vd_exce = ress.split(/^IF\(/)[1].gsub(/\)/, "")
                vd_first = vd_exce.split(",")[0]
                vd_second = vd_exce.split(",")[1]
                vd_last = vd_exce.split(",")[2]
                vad_first_front = vd_first.split(/\>|\</)[0]
                vad_first_back = vd_first.split(/\>|\</)[1]
                vad_opera = vd_first.scan(/\>|\</)[0]
                vad_contain = []
                vad_contain << vad_first_front
                vad_contain << vad_first_back
                vad_contain << vd_second
                vad_contain << vd_last
                vad_value = []
                vad_contain.each do |s|
                  if s == "0"
                    vad_value << 0.0
                  else
                    cv.value_def = "=" + s
                    vad_value << extract_cell(cv)
                  end
                end
                result_value = []
                vad_value.each do |r|
                  if r.nil?
                    result_value << 0.0
                  elsif r.class == Float
                    result_value << r
                  else
                    result_value << parse_cell(cache, [r], ress)
                  end
                end
                if eval("#{result_value[0]}" + vad_opera + "#{result_value[1]}")
                  count = result_value[2]
                else
                  count = result_value[3]
                end
              elsif ress.include? "+" or ress.match(/-[A-Z]/) and not ress.include? "IF"
                ac = operatcell(cache, extract_cell(cv), vl)
                asc = []
                vac_split = ress.scan(/(R(\[([0-9\-]+)\])?C(\[([0-9\-]+)\])?)([^\[A-Z]|$)/).map {|g| g[0]}
                ac.each_with_index do |z, index|
                  vac_split.each_with_index do |v, index1|
                    if index == index1
                      asc = ress.gsub!(v, "#{z}")
                    end
                  end
                end
                count << eval(asc).to_f.round(2)
              elsif ress == "0"
              elsif ress == "0.0"
              elsif ress.include? "+" or ress.match(/-[0-9]/) and not /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(ress)
                count = change_str(eval(ress).round(2)).gsub(/=/, "")
              else
                ae = extract_cell(cv)
                count = cell_compute(cache, ae)
              end
            end
          end
        else
          count = FmisReport::ReportCell.where(column_id: column_id, line_id: line_id).take
        end
      end
    end
    count
  end

  def if_compute(cache, cell, vd)
    vd_exce = vd.split(/IF\(/)[1].gsub(/\)/, "")
    vd_first = vd_exce.split(",")[0]
    vd_second = vd_exce.split(",")[1]
    arr_second = vd_second.scan(/(R(\[([0-9\-]+)\])?C(\[([0-9\-]+)\])?)([^\[A-Z]|$)/).map {|g| g[0]}
    vd_last = vd_exce.split(",")[2]
    vad_first_front = vd_first.split(/\>|\</)[0]
    vad_first_back = vd_first.split(/\>|\</)[1]
    vad_opera = vd_first.scan(/\>|\</)[0]
    vad_contain = []
    vad_contain << vad_first_front
    vad_contain << vad_first_back
    vad_contain << vd_second
    vad_contain << vd_last
    vad_value = []
    vad_contain.each do |s|
      if /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(s)
        cell.value_def = "=" + s
        vad_value << extract_cell(cell)
      else
        vad_value << s.to_f
      end
    end
    result_value = []
    vad_value.each do |r|
      if r.nil?
        result_value << 0.0
      elsif r.class == Float
        result_value << r
      elsif r[1].class == Array
        rr_value = []
        r.each do |rr|
          ac = parse_cell(cache, [rr], vd)
          if ac.class == Array
            rr_value << 0.0
          else
            rr_value << parse_cell(cache, [rr], vd)
          end
        end
        arr_val = 0
        rr_value.each_with_index do |z, index|
          arr_second.each_with_index do |v, index1|
            if index == index1
              arr_val = vd_second.gsub!(v, "#{z}")
            end
          end
        end
        result_value << eval(arr_val.gsub(",", "")).to_f
      else
        rea = parse_cell(cache, [r], vd)
        if rea.class == Float
          result_value << rea
        else
          result_value << rea.gsub(",", "").to_f
        end
      end
    end
    if eval("#{result_value[0]}" + vad_opera + "#{result_value[1]}")
      count = change_str(result_value[2].round(2))
    else
      count = change_str(result_value[3].round(2))
    end
    count
  end

  def round_compute(cache, cell, vd)
    _round_val = 0
    round_val = vd.split(/ROUND\(/)[1].split(",")[0] # R[1]C/R[2]C*#QWEE#
    unless round_val.include? "#"
      round_num = vd.split(/ROUND\(/)[1].split(",")[1].gsub(")", "") # 2
      vax_exc = round_val.scan(/(R(\[([0-9\-]+)\])?C(\[([0-9\-]+)\])?)([^\[A-Z]|$)/).map {|g| g[0]} # [R[1]C,R[2]C]
      round_contain = []
      vax_exc.each do |s|
        cell.value_def = "=" + s
        round_contain << extract_cell(cell)
      end
      round_value = []
      round_contain.each do |r|
        ac = parse_cell(cache, [r], vd)
        if ac.class == Array
          if ac.length == 0
            round_value << 0.0
          end
        else
          round_value << parse_cell(cache, [r], vd)
        end
      end
      round_value.each_with_index do |z, index|
        vax_exc.each_with_index do |v, index1|
          if index == index1
            round_val.gsub!(v, "#{z}")
          end
        end
      end
      val_result = 0.0
      begin
        eval(round_val)
      rescue
        val_result = 0.0
      else
        if eval(round_val).to_f.nan? or eval(round_val).to_f.infinite? == 1
          val_result = 0.0
        else
          val_result = eval(round_val).to_f
        end
      end
      _round_val = change_str(val_result.round(round_num.to_i))
    end
    _round_val
  end

  def mix_cells(cache, cell, ret)
    count = 0.0
    ret_contain = ret.gsub(/=/, "").scan(/(R(\[([0-9\-]+)\])?C(\[([0-9\-]+)\])?)([^\[A-Z]|$)/).map {|g| g[0]}
    va = []
    ret_contain.each_with_index do |_formula|
      if _formula.include? "["
        va << _formula
      end
    end
    va_value = []
    va.each do |v|
      cell.value_def = v
      va_value << extract_cell(cell)
    end
    data = []
    data.push ret.gsub(/=/, "")
    ac = []
    ac_val = FmisReport::ReportCell.where(column_id: va_value[0][0], line_id: va_value[0][1]).take
    if ac_val.value_def.start_with? '=' and ac_val.value_def.include? "R[" or ac_val.value_def.include? "C["
      ac.push ac_val.value_def.gsub(/=/, "")
    elsif ac_val.value_def.start_with? '=' and not /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(ac_val.value_def)
      data.push ac_val.value_def.gsub(/=/, "")
      num_val = eval(data[0].gsub(/R\[?(-?\d*)\]?C\[?(-?\d*)\]?/, data.pop))
      count = change_str(num_val.to_f.round(2))
    else
      daa = parse_cell(cache, va_value, cell)
      ac.push daa
      data.push ac
      if data[1].length == 1
        if data[1][0].class == Array
          ase = 0.0
        elsif data[1][0].class == Float
          ase = data[1][0]
        else
          l = lambda {|cache, line_id, column_id|
            eval(data[1][0].value_def)
          }
          ase = l.call(cache, data[1][0]['line_id'], data[1][0]['column_id'])
        end
        if ase.class == String
          ret = eval(ase.gsub(/=/, ""))
        else
          ret = ase.to_f
        end
        data_first = data[0]
        data_result = data_first.gsub!(/R\[?(-?\d*)\]?C\[?(-?\d*)\]?/, "#{ret}")
        count = change_str(eval("#{data_result.gsub(/=/, "")}").to_f.round(2))
      elsif data[1].length > 1
        data_last = data.flatten.last
        data_first = data[0]
        val = data_first.gsub!(/(R(\[([0-9\-]+)\])?C(\[([0-9\-]+)\])?)([^\[A-Z]|$)/, "#{data_last}")
        count = change_str(eval("#{val.gsub(/=/, "")}").to_f.round(2))
      end
    end
    count
  end

  # R[-27]C+R[-17]C+R[-14]C+R[-5]C+R[-4]C+R[-11]C
  def sum_compute(hash, cache, cell_value)
    sum_gather = []
    sum = []
    #[[1,0],[2,0]]
    if cell_value[1].class == Array
      cell_value.each do |c|
        cv = FmisReport::ReportCell.where(column_id: c[0], line_id: c[1]).take
        if cv.nil?
          c = 0.0
          sum_gather << c
        else
          if cv.value_def.starts_with? "="
            if cv.value_def.gsub(/=/, "").starts_with? "SUM"
              c = extract_cell(cv)
              if c.length > 1
                c.each do |cc|
                  co = FmisReport::ReportCell.where(column_id: cc[0], line_id: cc[1]).take
                  if co.nil?
                    cc = 0.0
                  elsif co.value_def.starts_with? "="
                    cc = extract_cell(co)
                  end
                  sum_gather << cc
                end
              end
            elsif cv.value_def.include? "+" or cv.value_def.match(/-[A-Z]/)
              mix = operatmix(hash, cache, cell_value, cv.value_def)
              sum_gather << mix
            elsif cv.value_def == "0"
              sum_gather << cv.value_def.to_f
            elsif cv.value_def.include? "ROUND"
              sum_gather << round_compute(cache, cv, cv.value_def)
            elsif cv.value_def.starts_with? "IF"
              sum_gather << if_compute(cache, cv, cv.value_def)
            else
              ec = extract_cell(cv)
              if ec.nil?
                a_value = 0.0
              else
                column_id = ec[0]
                line_id = ec[1]
                if hash[line_id]["c_#{column_id}"].nil?
                  a_value = 0.0
                else
                  a_value = hash[line_id]["c_#{column_id}"]['value_def'].gsub!(',', '').to_f
                  if a_value.nil?
                    a_value = 0.0
                  end
                end
              end
              sum_gather << a_value
            end
          elsif cv.value_def.include? "select"
            sum_gather << hash[cv.line_id]["c_#{cv.column_id}"]['value_def']
          else
            sum_gather << c
          end
        end
      end
    else
      # [1,0]
      res = result_verify(hash, cache, cell_value)
      if res.nil?
        sum_gather << 0.0
      else
        if res.class == Float
          sum_gather << result_verify(hash, cache, cell_value)
        elsif res == 0
          sum_gather << res.to_f
        else
          sc = res.gsub(",", "").to_f
          sum_gather << sc
        end
      end
    end
    sum_gather.each do |sm|
      if sm == 0
        sum << sm.to_f
      else
        if sm.class != Float
          if sm[1].class == Array
            cc = []
            sm.each do |ss|
              unless hash[ss[1]]["c_#{ss[0]}"].nil?
                s = hash[ss[1]]["c_#{ss[0]}"]['value_def'].gsub(',', '').to_f
                if s.nil?
                  s = 0.0
                end
                cc << s
              end
            end
            sum << eval(cc.join("+"))
          else
            unless hash[sm[1]]["c_#{sm[0]}"].nil?
              s0 = hash[sm[1]]["c_#{sm[0]}"]['value_def']
              if s0.start_with? '='
                spl = s0.gsub(/=/, "")
                if spl.start_with? 'SUM'
                  sum << sum_compute(hash, cache, cell_value)
                elsif spl.value_def.include? "+" or spl.value_def.match(/-[A-Z]/) and not ress.include? "IF"
                  mix = operatmix(hash, cache, cell_value, spl.value_def)
                  sum_gather << mix
                elsif /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(spl.value_def) and not spl.value_def include? "+" or not spl.value_def match(/-[A-Z]/) and not ress.include? "IF"
                  ec = extract_cell(spl)
                  column_id = ec[0]
                  line_id = ec[1]
                  a_value = hash[line_id]["c_#{column_id}"]['value_def'].gsub!(',', '').to_f
                  if a_value.nil?
                    a_value = 0.0
                  end
                  sum_gather << a_value
                elsif spl.include? "ROUND"
                  sum_gather << round_compute(cache, hash[sm[1]]["c_#{sm[0]}"], spl)
                end
              elsif s0.include? "ROUND"
                sum_gather << round_compute(cache, hash[sm[1]]["c_#{sm[0]}"], s0)
              elsif s0.starts_with? "IF"
                sum_gather << if_compute(cache, hash[sm[1]]["c_#{sm[0]}"], s0)
              elsif s0.class == String and s0.starts_with? '=' and /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(s0)
                #   =R[-1]C - ruby
              else
                s1 = s0.gsub(',', '').to_f
                if s1.nil?
                  s1 = 0.0
                end
                sum << s1
              end
            end
          end
        else
          sum << sm.to_f
        end
      end
    end
    ad = eval(sum.join("+"))
    ad
  end

  #eg：cell_value: [1,2] 结果验证
  def result_verify(hash, cache, cell_value)
    column_id = cell_value[0]
    line_id = cell_value[1]
    cv = FmisReport::ReportCell.where(column_id: column_id, line_id: line_id).take
    count = 0.0
    if cv.nil?
      count = 0.0
    else
      unless hash[line_id]["c_#{column_id}"].nil?
        vl = hash[line_id]["c_#{column_id}"]['value_def']
        if vl.nil?
          count = 0.0
        elsif vl == 0
          count = 0.0
        elsif vl.class == Float
          count = vl
        else
          if vl.starts_with? "="
            unless hash[line_id]["c_#{column_id}"].nil?
              if hash[line_id]["c_#{column_id}"]['value_def'].nil?
                count = 0.0
              else
                ress = hash[line_id]["c_#{column_id}"]['value_def'].gsub(/=/, "")
                if ress.starts_with? "SUM"
                  ae = extract_cell(cv)
                  ac = []
                  ae.each do |e|
                    if e.length > 1
                      ac << sum_compute(hash, cache, e)
                    else
                      ac << 0.0
                    end
                  end
                  count = eval("#{ac.join("+")}").to_f.round(2)
                elsif ress.include? "+" or ress.match(/-[A-Z]/) and not ress.include? "IF"
                  count = operatmix(hash, cache, extract_cell(cv), vl)
                elsif ress.include? "ROUND"
                  logger.info ress
                elsif ress.starts_with? "IF"
                  count = if_compute(cache, cv, ress)
                elsif ress == "0"
                  count = ress.to_f
                elsif ress == "0.0"
                  count = ress.to_f
                elsif ress.include? "+" or ress.match(/-[0-9]/) and not /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(ress)
                  count = change_str(eval(ress).round(2)).gsub(/=/, "")
                else
                  ae = extract_cell(cv)
                  count = sum_compute(hash, cache, ae)
                end
              end
            end
          else
            count = hash[line_id]["c_#{column_id}"]['value_def'].gsub(',', '').to_f
          end
        end
      end
    end
    count
  end

  def change_str(num)
    str = num.to_s
    nil while str.gsub!(/(.*\d)(\d\d\d)/, '\1,\2')
    return str
  end

  def parse_value(hash, cache, cell_value, value_def)
    value_def = value_def.gsub(/=/, "")
    logger.info value_def
    a = 0
    # +-混合
    if value_def.include? "+" or value_def.match(/-[A-Z]/) and not value_def.include? "ROUND" and not value_def.starts_with? "IF"
      opermix = operatmix(hash, cache, cell_value, value_def)
      a = change_str(opermix.gsub(",", "").to_f.round(2))
      # SUM
    elsif value_def.starts_with? "SUM"
      ac = []
      cell_value.each do |ce|
        unless ce.length == 0
          aq = sum_compute(hash, cache, ce)
          if aq.nil?
            ac << 0.0
          else
            ac << aq
          end
        end
      end
      a = change_str(eval(ac.join("+")).round(2))
      # R[1]C
    elsif /R\[?(-?\d*)\]?C\[?(-?\d*)\]?/.match(value_def) and not value_def.include? "ROUND" and not value_def.starts_with? "IF"
      count_value = result_verify(hash, cache, cell_value)
      if count_value.class == Float
        a = change_str(count_value.round(2))
      elsif count_value == 0
        a = 0.0
      else
        a = change_str(count_value.gsub(",", "").to_f.round(2))
      end
    elsif value_def.include? "ROUND"
      cell = FmisReport::ReportCell.where(column_id: cell_value[0], line_id: cell_value[1]).take
      data_val = round_compute(cache, cell, value_def)
      a = data_val
    elsif value_def.include? "IF"
      cell = FmisReport::ReportCell.where(column_id: cell_value[0], line_id: cell_value[1]).take
      a = if_compute(cache, cell, value_def)
    end
    a
  end

  def operatmix(hash, cache, cell_value, value_def)
    value_length = value_def.scan(/(R(\[([0-9\-]+)\])?C(\[([0-9\-]+)\])?)([^\[A-Z]|$)/).map {|g| g[0]}.length
    val_gather = []
    for i in 0..value_length - 1 do
      value = sum_compute(hash, cache, cell_value[i])
      if value.nil?
        val_gather << 0.0
      else
        val_gather << "#{value}"
      end
    end
    value_container = value_def.scan(/(R(\[([0-9\-]+)\])?C(\[([0-9\-]+)\])?)([^\[A-Z]|$)/).map {|g| g[0]}
    value_container.each_with_index do |a, index|
      val_gather.each_with_index do |va, index2|
        if index == index2
          value_def.gsub! "#{a}", "#{va}"
        end
      end
    end
    a = change_str(eval("#{value_def.gsub(/=/, "")}").to_f.round(2))
    a
  end

  def _flatten_column(report)
    sql = <<-SQL
SELECT A.*, GROUP_CONCAT(B.id) AS children FROM fmis_report_report_columns AS A
LEFT JOIN fmis_report_report_columns AS B ON B.parent_id = A.id
WHERE A.report_id = #{report.id}
GROUP BY A.id
order by A.position ASC
    SQL

    @cols = FmisReport::ReportColumn.find_by_sql(sql)

    ret = []
    @cols.each do |col|
      next if col.is_items
      next unless col.parent_id.blank?
      if col.children.blank?
        ret << col.id
      else
        ret << ordered_nodes(col.children)
      end
    end
    ret.flatten!
    return ret
  end

  def ordered_nodes(ids)
    ids = ids.split(',').map {|i| i.to_i}
    # p @cols
    nodes = @cols.find_all {|c| ids.include? c.id}.sort {|x, y| x.position <=> y.position}

    _ret = []
    nodes.each do |node|
      if node.children.blank?
        _ret << node.id
      else
        _ret << ordered_nodes(node.children)
      end
    end
    _ret
  end

end
