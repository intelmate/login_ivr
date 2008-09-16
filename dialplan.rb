#The main context to obtain our details, authentication and ultimate login to queues
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
  
}

#Context to obtain the agent login name
fetch_agent_username {
  
  cnt = 0
  @which_agent = 0
  valid_agent = FALSE
  while cnt < 3 do
    @agent_username = input 5, :timeout => 5.seconds, :play => "agent-user", :accept_key => "#"
    cnt += 1
    #Lets loop through each of the agent entries to see if we have a match
    @agents.each do |agent|
      if agent[:login] == @agent_username
        valid_agent = TRUE
        cnt = 10
        break
      else
        #Lets keep track of which agent we are at so we do not have to search in the next method and
        #may reference diretly
        @which_agent += 1
      end
    end
    #If we still do not have the right agent entered and have not depleted our retries play an 
    #incorrect message back to the caller
    if valid_agent == FALSE && cnt != 3
      play "agent-incorrect"
    end
  end
  
  #If the agent is valid then lets try for the password, otherwise hangup on the caller
  if valid_agent == TRUE
    +fetch_agent_passwd
  else
    play "vm-goodbye"
    hangup
  end
}

#Method to fetch the agent password
fetch_agent_passwd {

  cnt = 0
  valid_agent = FALSE
  while cnt < 3 do
    agent_passwd = input 5, :timeout => 5.seconds, :play => "agent-pass", :accept_key => "#"
    cnt += 1
    #If the pin entered matches the one to the agent entered then we have a valid login
    if @agents[@which_agent][:pin] == agent_passwd
      valid_agent = TRUE
      cnt = 10
    end
    if valid_agent == FALSE && cnt != 3
      play "agent-incorrect"
    end
  end
   
  if valid_agent == TRUE
    #If the caller entered by dialing *50 they are logging into the queue, if *51 they are leaving the queue
    if extension == "*50"
      @queues.each do |queue|
        execute("AddQueueMember", "#{queue}|SIP/#{callerid}")
      end
      play "agent-loginok"
      play "vm-goodbye"
      hangup
    elsif extension == "*51"
      @queues.each do |queue|
        execute("RemoveQueueMember", "#{queue}|SIP/#{callerid}")
      end
      play "agent-loggedoff"
      play "vm-goodbye"
      hangup
    end
  else
    play "vm-goodbye"
    hangup
  end
}