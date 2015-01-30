class PlayersController < ApplicationController

	respond_to :json

	def create
		player = Player.new(player_params)
		if player.save
			render :json => player, :status=>201
		end
	end

	def list
		players = Player.where('status = 1 ORDER BY rank')
		render :json => players, :status=>201
	end

	def player_params
		params.permit(:name)
	end


end
