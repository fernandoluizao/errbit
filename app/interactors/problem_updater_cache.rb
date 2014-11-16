class ProblemUpdaterCache
  attr_reader :problem

  def initialize(problem, notice=nil)
    @problem = problem
    @notice = notice
  end

  ##
  # Update cache information about child associate to this problem
  #
  # update the notices count, and some notice informations
  #
  # @return [ Problem ] the problem with this update
  #
  def update
    update_notices_count
    update_notices_cache
    problem
  end

private

  def update_notices_count
    if @notice
      problem.inc(:notices_count, 1)
    else
      problem.update_attribute(:notices_count, problem.notices.count)
    end
  end

  ##
  # Update problem statistique from some notice information
  #
  def update_notices_cache
    first_notice = notices.first
    last_notice = notices.last
    notice ||= @notice || first_notice

    attrs = {}
    attrs.merge!(
      :first_notice_at          => first_notice.created_at,
      :first_notice_commit      => first_notice.git_commit,
      :first_notice_environment => first_notice.environment_name
    ) if first_notice
    attrs.merge!(
      :last_notice_at           => last_notice.created_at,
      :last_notice_commit       => last_notice.git_commit,
      :last_notice_environment  => last_notice.environment_name
    ) if last_notice
    attrs.merge!(
      :message     => notice.message,
      :where       => notice.where,
      :messages    => attribute_count(:message, messages),
      :hosts       => attribute_count(:host, hosts),
      :user_agents => attribute_count(:user_agent_string, user_agents)
    ) if notice
    problem.update_attributes!(attrs)
  end

  def notices
    @notices ||= problem.notices.order("created_at ASC")
  end

  def messages
    @notice ? problem.messages : {}
  end

  def hosts
    @notice ? problem.hosts : {}
  end

  def user_agents
    @notice ? problem.user_agents : {}
  end

  def attribute_count(value, init)
    init.tap do |counts|
      notices.each do |notice|
        counts[attribute_index(notice.send(value))] ||= {
          'value' => notice.send(value),
          'count' => 0
        }
        counts[attribute_index(notice.send(value))]['count'] += 1
      end
    end
  end

  def attribute_index(value)
    @attributes_index ||= {}
    @attributes_index[value.to_s] ||= Digest::MD5.hexdigest(value.to_s)
  end

end
