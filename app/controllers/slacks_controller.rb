class SlacksController < ApplicationController


	def respond
		command = params[:text].split[0]
		body = params[:text].split[1]
		case command
		when 'add_me'
			max_rank = Player.maximum('rank') || 0
			Player.create(:name=> params[:user_name], :status=> 1, :rank=> max_rank+1)
			message = "Player #{params[:user_name]} added with rank #{max_rank+1}"
		when 'kill_me'
			player = Player.find_by(:name => params[:user_name])
			player.destroy if !player.blank?
			message = "I killed #{params[:user_name]}" if !player.blank?
			message = "Couldn't find player" if player.blank?
		when 'im_afk'
			player = Player.find_by(:name => params[:user_name])
			current_rank = player.rank
			player.update(:status => 0, :last_rank=>player.rank, :rank=>0) if !player.blank?
			players  = Player.where('status = 1 AND rank > 0').order('rank')
			i = 1
			players.each do |player|
				player.update(:rank=>i)
				i = i + 1
			end
			message = "You are now inactive.  You must challenge at rank #{current_rank} in order to come back.}"
		when 'ranking'
			players  = Player.where('status = 1 AND rank > 0').order('rank')
			i = 1
			message = ''
			players.each do |player|
				message = message + "Rank #{player.rank} is #{player.name}! "
				i = i + 1
			end
		else
			message = 'Invalid command'
		end

		render :json => {:message=>message}, :status=>201
	end


end
