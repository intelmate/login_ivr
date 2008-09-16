from_internal {
  answer
  
  #Method to obtain all of the agent details from /etc/asterisk/agents.conf
  cnt = 0
  @agents = []
  file = File.open("/etc/asterisk/agents.conf", "r") do |infile|
    while (line = infile.gets)
      if line.slice(0,5) == 'agent'
        agent_line = line.split("=>")
        agent_line = agent_line[1].split(",")
        @agents[cnt] = {:login => agent_line[0].lstrip, :pin => agent_line[1], :name => agent_line[2].rstrip}
        cnt += 1
      end
    end
  end
  
  #Method to obtain all of the queue details from /etc/asterisk/queues_additional.conf
  cnt = 0
  @queues = []
  file = File.open("/etc/asterisk/queues_additional.conf", "r") do |infile|
    while (line = infile.gets)
      if line.slice(0,1) == '['
        @queues[cnt] = line.slice(1, line.length - 3)
        cnt += 1
      end
    end
  end   
  
  +fetch_agent_username
  
  #execute("AgentCallbackLogin", agent_login, "", callerid.to_s + "@from-internal")
  
}

fetch_agent_username {
  
  cnt = 0
  @which_agent = 0
  valid_agent = FALSE
  while cnt < 3 do
    @agent_username = input 5, :timeout => 5.seconds, :play => "agent-user", :accept_key => "#"
    cnt += 1
    @agents.each do |agent|
      if agent[:login] == @agent_username
        valid_agent = TRUE
        cnt = 10
        break
      else
        @which_agent += 1
      end
    end
    if valid_agent == FALSE
      play "agent-incorrect"
    end
  end
   
  if valid_agent == TRUE
    +fetch_agent_passwd
  else
    play 'goodbye'
    hangup
  end
}

fetch_agent_passwd {

  cnt = 0
  valid_agent = FALSE
  while cnt < 3 do
    agent_passwd = input 5, :timeout => 5.seconds, :play => "agent-pass", :accept_key => "#"
    cnt += 1
    if @agents[@which_agent][:pin] == agent_passwd
      valid_agent = TRUE
      cnt = 10
    end
    if valid_agent == FALSE
      play "agent-incorrect"
    end
  end
   
  if valid_agent == TRUE
    play 'tt-monkeys'
  else
    play 'goodbye'
    hangup
  end
}
