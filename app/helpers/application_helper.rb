# encoding = utf-8
require 'base64'

module ApplicationHelper

  def check_user_session
    token = params[:token]
    # byebug
    if token.nil?
      begin
        token = request.headers.fetch('Authorization')
        params[:token] = token
      rescue => e
        logger.info(e.message)
      end
    end
    
    return false if token.nil? # or ((/bearer\s/ =~ token).nil? and (/bear\s/ =~ token).nil?)

    token = Base64.decode64 token.split(' ')[1]
    user_id, session_token = token.split(':')

    

    session = Session.exists?(['user_id=? and token=?', user_id, session_token])
    unless session.blank?
      User.current = (User.find(user_id) rescue nil)
      return true
    else
      User.current = nil
      return false
    end
  end

  def render_upload_success_json(params = {})
    script = "<script>(function(){document.domain=document.domain;})();</script>"
    render :text => "#{script}#{{:status => 'success'}.merge(params).to_json}"
  end

  def render_upload_failure_json(errmsg, params = {}, exception = nil)
    log_exception(exception)
    script = "<script>(function(){document.domain=document.domain;})();</script>"
    render :text => "#{script}#{{:status => 'failure', :errmsg => errmsg}.merge(params).to_json}"
  end

  def render_success_json(params = {})
    render :json => {:status => 'success'}.merge(params).to_json
  end

  def render_failure_json(errmsg, params = {}, exception = nil)
    log_exception(exception)
    render :json => {:status => 'failure', :errmsg => errmsg}.merge(params).to_json
  end


  def update
    modify_object = @model_type.find_by_id(params[:id])
    unless modify_object.blank?
      #Remove the useless columns
      p = filter(params, @model_type)
      failures = []
      begin
        r = modify_object.update_attributes(p)
      rescue Exception => ex
        r = false
        failures = [ex.message]
      end
      if r
        if self.instance_variables.include? :@additional_params and @additional_params.has_key? :update
          param_name = @additional_params[:update][0]
          method_name = @additional_params[:update][1]
          if param_name.eql? :blank or params[param_name]
            self.method(method_name).call(modify_object, params[param_name])
          end
        end
        render_success_json
      else
        failures += modify_object.errors.full_messages
        logger.info(failures.join(','))
        render_failure_json failures.join(',')
      end
    else
      render_failure_json "no object to update"
    end
  end

  def add
    p = filter(params, @model_type)
    if @model_type.column_names.include? 'creator_id'
      p[:creator_id] = User::User.current.id
    end
    new_object = @model_type.new(p)
    failures = []
    begin
      r = new_object.save
    rescue Exception => ex
      r = false
      failures = [ex.message]
    end
    if r
      if self.instance_variables.include? :@additional_params and @additional_params.has_key? :add
        param_name = @additional_params[:add][0]
        method_name = @additional_params[:add][1]
        if param_name.eql? :blank or params[param_name]
          self.method(method_name).call(new_object, params[param_name])
        end
      end
      render_success_json
    else
      failures += new_object.errors.full_messages
      render_failure_json failures
    end
  end

  def delete
    delete_model = params[:delete_model] || 1
    c = @model_type.where('id IN (?)', [params[:id]]).update_all(:status => delete_model)
    if c > 0
      if self.instance_variables.include? :@additional_params and @additional_params.has_key? :delete
        param_name = @additional_params[:delete][0]
        method_name = @additional_params[:delete][1]
        if param_name.eql? :blank or params[param_name]
          self.method(method_name).call(params[:id], params[param_name])
        end
      end
      render_success_json
    else
      render_failure_json "no object updated"
    end
  end

  def query_p2_style(sql = nil, need_render = true, count_key = 'id', full_return=false, &block)
    r = get_query_result(sql, count_key)
    yield r[:records] if block_given?
    unless need_render
      if full_return
        return r[:records], r[:count], r[:errmsg], r[:failed]
      else
        return r[:records]
      end
    else
      render_query_result(r[:records], r[:count], r[:errmsg], r[:failed])
    end
  end

  alias_method :query, :query_p2_style

  def get_query_result(sql = nil, count_key = 'id')
    limit = (params[:limit] || 50).to_i
    offset = (params[:start] || 0).to_i
    conditions = []
    conditions << convert_where_clause_to_condition(params[:criteria])
    conditions << parse_grid_filters(params[:filter])

    condition = conditions.join(" AND ")

    sort = parse_sort_clause(params[:sort])
    errmsg = nil
    failed = false
    if condition.blank?
      failed = true
      errmsg = 'where param is null.'
    else
      if sql.blank?
        records = @model_type.where(condition).limit(limit).offset(offset).order(sort)
        _sql = "SELECT COUNT(#{count_key}) FROM %s WHERE %s" % [@model_type.table_name, condition]
        count = @model_type.count_by_sql(_sql)
      elsif sql.is_a? String
        condition = "WHERE %s" % condition unless condition.blank?
        sort = sort.blank? ? '' : "ORDER BY #{sort}"
        limit = (limit == -1) ? '' : "LIMIT #{offset},#{limit}"
        _sql = "SELECT * FROM (%s) AS ZZ %s %s %s" % [sql, condition, sort, limit]
        logger.info('APP QUERY:')
        logger.info _sql
        records = @model_type.find_by_sql(_sql)
        unless count_key.blank?
          _sql = "SELECT COUNT(#{count_key}) FROM (%s) AS ZZ %s" % [sql, condition]
          count = @model_type.count_by_sql(_sql)
        end
      elsif sql.is_a?Hash
        _condition = sql[:condition]
        table = sql[:table]
        fields = sql[:fields]
        count_field = sql[:count]
        group = sql[:group] || ''
        _sort = sql[:order]
        final_sort = []
        final_sort << _sort unless _sort.blank?
        final_sort << sort unless sort.blank?
        __sort = "ORDER BY #{final_sort.join(',')}" unless final_sort.blank?
        sort = sort.blank? ? '' : "ORDER BY #{sort}"
        limit = (limit == -1) ? '' : "LIMIT #{offset},#{limit}"
        final_condition = []
        final_condition << "(#{_condition})" unless _condition.blank?
        final_condition << "(#{condition})" unless condition.blank?
        condition = final_condition.join(" AND ")
        condition = "WHERE %s" % condition unless condition.blank?
        _sql = "SELECT %s FROM %s %s %s %s %s" % [fields.join(","), table, condition, group, sort, limit]
        logger.info('APP QUERY:')
        logger.info _sql
        records = @model_type.find_by_sql(_sql)
        unless count_field.blank?
          unless group.blank?
            _sql = "SELECT COUNT(*) FROM (SELECT %s FROM %s %s %s) AS ZZ" % [fields.join(','), table, condition, group]
          else
            _sql = "SELECT #{count_field} FROM %s %s" % [table, condition]
          end
        else
          count = 0
        end
      end

      records.collect! { |record| record.attributes }

      unless @repack_method.blank?
        @repack_method.call(records)
      end
    end
    return {
        :records => records,
        :count => count,
        :errmsg => errmsg,
        :failed => failed
    }
  end

  def get_query_sql(sql)
    limit = (params[:limit] || 50).to_i
    offset = (params[:start] || 0).to_i
    conditions = []
    conditions << convert_where_clause_to_condition(params[:criteria])
    conditions << parse_grid_filters(params[:filter])
    condition = conditions.join(" AND ")
    sort = parse_sort_clause(params[:sort])
    condition = "WHERE %s" % condition unless condition.blank?
    sort = sort.blank? ? '' : "ORDER BY #{sort}"
    limit = (limit == -1) ? '' : "LIMIT #{offset},#{limit}"
    _sql = "SELECT * FROM (%s) AS ZZ %s %s %s" % [sql, condition, sort, limit]
  end

  def render_query_result(records, count, errmsg = nil, failed = false, filename = nil, &block)
    if failed
      info = {:records => [], :count => 0, :errmsg => errmsg, :status => 'failure'}
    else
      info = {:records => records, :count => count, :status => 'success'}
    end
    yield info if block_given?
    render :json => info.to_json
  end

  def count_records(sql, model = nil)
    _sql = "SELECT COUNT(*) AS count FROM (#{sql}) AS Z"
    if model.nil?
      count = ActiveRecord::Base.connection.select_one(_sql)
      count['count']
    else
      model.count_by_sql(_sql)
    end
  end

  def self.system_configs
    {
      'demo': File.exist?('demo'),
      'company': Rails.application.config.company
    }
  end

#####################################################################################
  private
  def log_exception(exception)
    unless exception.nil?
      logger.info(exception.message)
      traceback = exception.backtrace.join("\n\t")
      logger.info(traceback)
    end
  end

## term = "[{"property":"tradeDate","direction":"DESC"}]"
## return "tradeDate DESC"
  def parse_sort_clause(term)
    unless term.blank?
      if term.is_a?String
        json = JSON.parse(term)
      else
        json = term
      end
      clauses = []
      json.each do |item|
        clauses.push("#{item['property']} #{item['direction'].nil? ? 'ASC' : item['direction']}")
      end
      if clauses.size > 0
        "#{clauses.join(', ')}"
      else
        nil
      end
    end
  end

  def convert_where_clause_to_condition(criteria)
    if criteria.blank?
      return '1'
    else
      conditions = []
      criteria.each_pair do |_column, _key|
        conditions << "(#{_column} LIKE '%#{_key}%')"
      end
      return "(#{conditions.join(' OR ')})"
    end
  end

  def filter(original_params, model_type)
    columns = model_type.column_names
    ret = {}
    original_params.each_pair do |_k, _v|
      if _k.to_s != 'id' and columns.include? _k.to_s
        ret[_k] = original_params[_k]
      end
    end
    return ret
  end

  def parse_grid_filters(filters)
    return 1 if filters.blank?
    filters = JSON.parse(filters) if filters.is_a?(String)
    conditions = []
    filters.each do |filter|
      value_refactor = lambda {|val| "'#{val}'"}
      operator = if filter['operator'].eql? 'eq'
        '='
      elsif filter['operator'].eql? 'lt'
        '<'
      elsif filter['operator'].eql? 'gt'
        '>'
      elsif filter['operator'].eql? 'in'
        value_refactor = lambda {|val| "('#{val.join('\',\'')}')"}
        'in'
      elsif filter['operator'].eql? 'like'
        value_refactor = lambda {|val| "'%#{val}%'"}
        'like'
      end

      conditions << "#{filter['property']} #{operator} #{value_refactor.call(filter['value'])}"
    end

    conditions.size > 0 ? conditions.join(" AND ") : 1
  end

  def allow_iframe
     response.headers['X-Frame-Options'] = 'ALLOWALL'#'ALLOW-FROM http://127.0.0.1:4000'
  end


end
