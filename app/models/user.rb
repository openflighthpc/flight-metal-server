# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Metal Server.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Metal Server is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cloud. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Metal Server, please visit:
# https://github.com/openflighthpc/metal-server
#===============================================================================

require 'hashie'
require 'jwt'

class User < Hashie::Dash
  class << self
    attr_writer :jwt_shared_secret

    def jwt_shared_secret
      User.instance_variable_get(:@jwt_shared_secret) || raise(<<~ERROR.chomp)
        The json web token has not been set on the User model
      ERROR
    end

    def from_jwt(token)
      body, _ = JWT.decode(token,
                           jwt_shared_secret,
                           true,
                           { algorithm: 'HS256' })
      new(**body['data'])
    rescue JWT::ExpiredSignature
      raise Sinja::UnauthorizedError, 'Your authorization token has expired'
    rescue JWT::InvalidIatError
      raise Sinja::UnauthorizedError, 'Your authorization token as an invalid "issued at" time'
    rescue JWT::VerificationError
      raise Sinja::UnauthorizedError, 'Unrecognize authorization signature'
    rescue JWT::DecodeError
      raise Sinja::UnauthorizedError, <<~ERROR.squish
        An error occurred when decoding your authorization token. Insure the
        Authorization Header has been set correctly and try again.
      ERROR
    end
  end

  property :user, default: false
  property :admin, default: false

  def generate_jwt
    JWT.encode(self.to_h, self.class.jwt_shared_secret, 'HS256')
  end

  def role
    if admin
      :admin
    elsif user
      :user
    else
      :unknown
    end
  end
end

