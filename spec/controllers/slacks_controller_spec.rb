require 'rails_helper'

RSpec.describe SlacksController, :type => :controller do
    after(:each) do
        Player.delete_all
        Challenge.delete_all
    end

    it "creates a new user" do
        params = {
            :text => 'add_me',
            :user_name => 'alice'
        }
        post :respond, params
        expect(Player.find_by(name: 'alice').blank?).to be false
    end
    
    it "deletes a user" do
        Player.create(:name=> 'alice')
        params = {
            :text => 'kill_me',
            :user_name => 'alice'
        }
        post :respond, params
        expect(Player.find_by(name: 'alice').blank?).to be true
    end
    
    it "takes a player off the ladder if they declare that they're afk" do
        Player.create(:name => 'alice', :rank => 1, :status => 1)
        Player.create(:name => 'ryo', :rank => 2, :status => 1)
        params = {
            :text => 'im_afk',
            :user_name => 'alice'
        }
        post :respond, params
        expect(Player.find_by(name: 'alice').last_rank).to be(1)
        expect(Player.find_by(name: 'alice').rank).to be(0)
        expect(Player.find_by(name: 'alice').status).to be(-1)
        expect(Player.find_by(name: 'ryo').rank).to be(1)

    end
    
    it "returns a ranking of players" do 
        Player.create(:name => 'alice', :rank => 1, :status => 1)
        Player.create(:name => 'ryo', :rank => 2, :status => 1)

        params = {
            :text => 'ranking',
            :user_name => 'alice'
        }
        post :respond, params
        res = JSON.parse(response.body)
        expect(res["text"]).to include("Rank 1 is alice!")
    end

    it "creates a challenge between two players" do
        alicePlayer = Player.create(:name => 'alice', :rank => 1, :status => 1)
        ryoPlayer = Player.create(:name => 'ryo', :rank => 2, :status => 1)

        params = {
            :text => 'challenge ryo',
            :user_name => 'alice'
        }
        post :respond, params
        res = JSON.parse(response.body)
        expect(res["text"]).to include("Challenge to ryo issued")
        expect(Player.find_by(name: 'alice').status).to be(0)
        expect(Player.find_by(name: 'ryo').status).to be(0)
        expect(Challenge.exists?(from_id: alicePlayer[:id], to_id: ryoPlayer[:id])).to be true
    end

    describe ".accept" do

        subject do 
            params = {
                :text => 'accept',
                :user_name => 'alice'
            }
            post :respond, params
        end

        context 'when no challenges are available' do
            let(:alicePlayer){ Player.create(:name => 'alice', :rank => 1, :status => 1) }
            it "it tells you no challenges are available" do
                expect { subject }.not_to change{alicePlayer}
                expect(JSON.parse(response.body)["text"]).to include("No active challenges to you found")
            end
        end

        context 'when a challenge is available' do
            let!(:alicePlayer){ Player.create(:name => 'alice', :rank => 1, :status => 1) }
            let!(:ryoPlayer){ Player.create(:name => 'ryo', :rank => 2, :status => 1) }
            let!(:challenge){ Challenge.create(:to_id => alicePlayer[:id], :from_id => ryoPlayer[:id], :status => 0) }

            it "allows a player to accept a challenge" do
                expect { subject }.to change{challenge}
                expect(JSON.parse(response.body)["text"]).to include("Challenge from ryo accepted, go play")
                expect(challenge.status).to eq(1)  
            end

        end

    end

    it "allows a player to decline a challenge" do

    end

end
