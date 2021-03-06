require 'httparty'
require 'json'

module Api
	module V1
		class UsersController < ApplicationController
			skip_before_action :verify_authenticity_token

			def index
				users = User.all
				response = []
				users.each do |user|
					userResponse = {
						id: user.id,
						name: user.name,
						email: user.email,
						about: user.about,
						karma: user.karma,
						created_at: user.created_at,
						updated_at: user.updated_at
					}
					response.push(userResponse)
				end
				render json: {status: 'SUCCESS', message: 'Users', data: response}, status: :ok
			end

			def show
				user = User.where("id = ?", params[:id])
				if user.empty?
					render json: {status: 'ERROR', message: 'User does not exist', data: nil}, :status => 404
				else
					user= User.find(params[:id])
					response = {
						name: user.name,
						email: user.email,
						karma: user.karma,
						about: user.about,
						created_at: user.created_at
					}
					render json: {status: 'SUCCESS', message: 'User profile', data: response}, status: :ok
				end
			end

			def update
				begin
					user = User.where(:api_key => request.headers['Authorization']).first
					if user
						current_user = user
					end
				rescue Exception => e
					#empty
				end
				if current_user
					user = User.where("id = ?", params[:id])
					if user.empty?
						render json: {status: 'ERROR', message: 'User does not exist', data: nil}, :status => 404
					else
						user= User.find(params[:id])
						if user == current_user
							response = {
								name: user.name,
								email: user.email,
								karma: user.karma,
								about: user_params[:about],
								created_at: user.created_at
							}
							user.update(response)
							render json: {status: 'SUCCESS', message: 'Profile updated', data:
								response}, status: :ok
						else
							render json: {status: 'ERROR', message: 'Cannot update other profiles', data: nil},
									status: :unprocessable_entity
						end
					end
				else
					render json: {status: 'ERROR', message: 'Error in authenticity', data: nil}, :status => 403
				end
			end

			def id
				user = User.where(:api_key => request.headers['Authorization'])
				if user.empty?
					render json: {status: 'ERROR', message: 'User does not exist', data: nil}, :status => 404
				else
					id = user[0].id
					render json: {status: 'SUCCESS', message: 'User Id', data: id}, :status => 200
				end
			end

			def token
				user = User.where("id = ?", params[:id])
				if user.empty?
					render json: {status: 'ERROR', message: 'User do not exist', data: nil}, :status => 404
				else
					user = User.find(params[:id])
					render json: {status: 'SUCCESS', message: 'Token', data: user.api_key}, status: :ok
				end
			end

			def signin
				begin
					url = "https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=#{params[:token]}"
			  	response = HTTParty.get(url, :verify => false)
					data = response.parsed_response
					user = User.where(:uid => data['sub'])
					if user.empty?
						newuser = User.new
						newuser.provider = "google_oauth2"
						newuser.uid = data['sub']
						newuser.email = data['email']
						newuser.name = data['name']
						newuser.karma = 1
						if newuser.save
							json = {
								name: newuser.name,
								karma: newuser.karma,
								api_key: newuser.api_key,
								id: newuser.id
							}
							render json: {status: 'SUCCESS', message: 'Token', data: json}, :status => 200
						else
							render json: {status: 'ERROR', message: 'Token', data: {}}, :status => 403
						end
					else
						json = {
							name: user[0].name,
							karma: user[0].karma,
							api_key: user[0].api_key,
							id: user[0].id
						}
						render json: {status: 'SUCCESS', message: 'Token', data: json}, :status => 200
					end
				rescue => e
					print(e)
					puts "error"
					render json: {status: 'ERROR', message: 'Token', data: {}}, :status => 403
				end
			end

			def siginparams
				params.permit(:token)
			end

			def user_params
				params.require(:user).permit(:about)
			end

		end
	end
end
