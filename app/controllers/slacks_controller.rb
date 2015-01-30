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
		when 'change_status'
			player = Player.find_by(:name => params[:user_name])
			player.update(:status => body) if body
		else
			message = 'Invalid command'
		end

		render :json => {:message=>message}, :status=>201
	end


end
