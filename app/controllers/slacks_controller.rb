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
			self.rerank
		when 'im_afk'
			player = Player.find_by(:name => params[:user_name])
			current_rank = player.rank
			deactivate(player)
			message = "You are now inactive.  You must challenge at rank #{current_rank} in order to come back.}"
		when 'ranking'
			players  = Player.where('status = 1 AND rank > 0').order('rank')
			i = 1
			message = ''
			players.each do |player|
				message = message + "Rank #{player.rank} is #{player.name}! "
				i = i + 1
			end
		when 'challenge'
			from_user = Player.find_by(:name => params[:user_name])
			to_user = Player.find_by(:name => body)

			if from_user.blank?
				message = "You are not a ping pong player"
			elsif to_user.blank?
				message = "#{body} is not a ping pong player"
			elsif from_user.status == 0
				message = "You cannot issue a challenge because you are already in a challenge or match"
			elsif from_user.status == -1
				message = "You cannot issue a challenge because you are inactive, type im_back to get back on the ranking first"
			elsif to_user.status == 0
				message = "#{to_user.name} is already in a challenge or match"
			elsif to_user.status == -1
				message = "#{to_user.name} is not active right now.  They are OOO or injured, take it easy."
			elsif ([to_user.rank, from_user.rank].max - [to_user.rank, from_user.rank].min) > 2
				message = "Challenge not valid, ranking difference is more than 2"
			elsif from_user.status == 1 && to_user.status ==1
				challenge = Challenge.create(:from_id => from_user.id, :to_id=>to_user.id, :status=> 0)
				from_user.update(:status=>0)
				to_user.update(:status=>0)
				message = "Challenge to #{to_user.name} issued"
			end

		when 'accept'
			user = Player.find_by(:name => params[:user_name])

			if user.blank?
				message = "You are not a ping pong player"
			else
				challenge = Challenge.where(:to_id => user.id, :status=>0).first
				if challenge
					from_user = Player.find(challenge.from_id)
					challenge.update(:status=>1)
					message = "Challenge from #{from_user.name} accepted, go play"
				else
					message = "No active challenges to you found"
				end
			end

		when 'decline'
			user = Player.find_by(:name => params[:user_name])
			if user.blank?
				message = "You are not a ping pong player"
			else
				challenge = Challenge.where(:to_id => user.id, :status=>0).first
				if challenge
					from_user = Player.find(challenge.from_id)
					to_user = Player.find(challenge.to_id)
					last_rank = to_user.rank
					challenge.update(:status=>-1)
					from_user.update(:status=>1)
					deactivate(to_user)
					message = "Challenge from #{from_user.name} declined, you are now off the ranking.  You must challenge at #{last_rank} to get back.  Type im_back when you're ready"
				else
					message = "No active challenges to you found"
				end
			end
		when 'i_won'
			user = Player.find_by(:name => params[:user_name])
			challenge = Challenge.where("(to_id = ? OR from_id = ?) AND status = 1", user.id, user.id).first
			if challenge
				to_user = Player.find(challenge.to_id)
				from_user = Player.find(challenge.from_id)
				players = Player.where('status != -1 AND rank > 0').order('rank')
				player_array = []
				players.each do |player|
					player_array << player.id
				end

				if user == from_user
					if user.rank > to_user.rank
						player_array.delete(user.id)	
						player_array.insert(to_user.rank-1, user.id)
						rank(player_array)
					end
				elsif user == to_user
					if user.rank > from_user.rank
						player_array.delete(user.id)
						player_array.insert(from_user.rank-1, user.id)
						rank(player_array)
					end
				end

				to_user.update(:status => 1)
				from_user.update(:status => 1)
				challenge.update(:status => -1)
				user = Player.find_by(:name => params[:user_name])
				message = 'Good job! Your ranking is now #{user.rank}'
			else
				message = 'You are not in an active match right now.  Either accept one, or challenge someone'
			end
		when 'i_lost'
			user = Player.find_by(:name => params[:user_name])
			challenge = Challenge.where("(to_id = ? OR from_id = ?) AND status = 1", user.id, user.id).first
			if challenge
				to_user = Player.find(challenge.to_id)
				from_user = Player.find(challenge.from_id)
				players = Player.where('status != -1 AND rank > 0').order('rank')
				player_array = []
				players.each do |player|
					player_array << player.id
				end

				if user == from_user
					if user.rank < to_user.rank
						player_array.delete(to_user.id)	
						player_array.insert(user.rank-1, to_user.id)
						rank(player_array)
					end
				elsif user == to_user
					if user.rank < from_user.rank
						player_array.delete(from_user.id)
						player_array.insert(user.rank-1, from_user.id)
						rank(player_array)
					end
				end

				to_user.update(:status => 1)
				from_user.update(:status => 1)
				challenge.update(:status => -1)
				user = Player.find_by(:name => params[:user_name])
				message = 'Sorry that you lost, your ranking is now #{user.rank}'
				
			else
				message = 'You are not in an active match right now.  Either accept one, or challenge someone'
			end
		when 'im_back'
		else
			message = 'Invalid command'
		end

		render :json => {:text=>message}, :status=>201
	end


	def deactivate(player)
		player.update(:status => -1, :last_rank=>player.rank, :rank=>0) if !player.blank?
		self.rerank
	end

	def rerank
		players = Player.where('status != -1 AND rank > 0').order('rank')
		i = 1
		players.each do |player|
			player.update(:rank=>i)
			i = i + 1
		end
	end

	def rank(player_array)
		i = 1
		player_array.each do |player|
			Player.find(player).update(:rank=>i)
			i = i + 1
		end
	end

end
