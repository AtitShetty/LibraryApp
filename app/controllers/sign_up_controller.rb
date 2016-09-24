class SignUpController < ApplicationController
  def new
    @reader = User.new
  end

  # POST
  def create


    @reader = User.new(reader_params)

    if(@reader.save)
      redirect_to login_path, notice: "User #{@reader.name} Successfully Created. PLease Login"
    else
      @reader.errors
      redirect_to logout_path
    end
  end

private

  def reader_params
    params.require(:user).permit(:name, :password, :password_confirmation, :role, :address, :phoneNumber, :email)
  end
end
