class BookingsController < AccessController
  before_action :set_booking, only: [:show, :edit, :update, :destroy, :bookingMailer, :send_mail]


  # GET /bookings
  # GET /bookings.json
  # Get upcoming, past and deleted bookings.
  def index
    @upcomingbooking = Booking.where("intime >= ?",DateTime.current).order(:intime)
    @pastbooking = Booking.where("intime < ?",DateTime.current).order(intime: :desc)
    @deletedbooking = Deletedbooking.all.order(intime: :desc)

  end

  # GET /bookings/1
  # GET /bookings/1.json
  def show

  end

  # GET /bookings/new
  def new
    @booking = Booking.new
  end

  # GET /bookings/1/edit
  def edit
  end

  # POST /bookings
  # POST /bookings.json
  # Create new bookings taking into account who is actually booking, whether admin or normal user
  # Also check if user has the ability to book multiple rooms at the same time.
  def create
    @userid=session[:user]['bookinguserid']
    @room_no=params[:room_no]
    @date=params[:date].to_date
    @t=params[:time]
    @intime = Time.new(@date.year, @date.month, @date.day,@t.to_i,0, 0)
    @booking = Booking.new({:userid=>@userid,:room_no=>@room_no,:intime=>@intime})

    if((session[:user]['role']) != "Normal" or (session[:user]['allow_multiple']))
      @condition=@booking.save(validate: false)
    else
      @condition=@booking.save
      end

    respond_to do |format|
      if @condition
        format.html { redirect_to @booking, notice: 'Booking was successfully created.' }
        format.json { render :show, status: :created, location: @booking }
      else
      #  format.html { render :new }
        format.html { redirect_to static_search_path(:bookinguserid => @userid ), notice:'You can only book one room at one time'  }
        format.json { render json: @booking.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bookings/1
  # PATCH/PUT /bookings/1.json
  def update
    respond_to do |format|
      if @booking.update(booking_params)
        format.html { redirect_to @booking, notice: 'Booking was successfully updated.' }
        format.json { render :show, status: :ok, location: @booking }
      else
        format.html { render :edit }
        format.json { render json: @booking.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bookings/1
  # DELETE /bookings/1.json
  # Delete bookings from bookings table and add them to deletedbookings table.
  def destroy
    @deletedbooking = Deletedbooking.new({:userid=>@booking.userid,:room_no=>@booking.room_no,:intime=>@booking.intime})
    @deletedbooking.save
    @booking.destroy
    respond_to do |format|
     # format.html { redirect_to "/bookings/booking_history/"+session[:user]['id'].to_s, notice: 'Booking was successfully destroyed.' }
      format.html { redirect_to bookingHistory_path(:historyuserid => session[:user]['historyuserid']), notice: 'Booking was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  #Search for avaialble rooms based on various criteria
  def search
pass_params=params
pass_params[:date]=Date.new(params[:date][:year].to_i,params[:date][:month].to_i,params[:date][:day].to_i)
@return_params= Booking.find_availiblty(pass_params)
render :new, data: pass_params
return @return_params

  end

  #Decide who is actually booking, whether it is a user or Admin. Render search page after that
  def search_static
    session[:user]['bookinguserid']= params[:bookinguserid] if params.key? "bookinguserid"
    render :search
  end

#Decide who is checking user history, whether it is an admin or the user himself
  def booking_history
    session[:user]['historyuserid'] = params[:historyuserid] if params.key? "historyuserid"
  end

  # Return upcoming, past and deleted bookings for a particular room.
  def room_history
    roomid = params[:historyroomid] if params.key? "historyroomid"
    @upcomingbooking = Booking.where("room_no = ? AND intime >= ?",roomid,DateTime.current).order(:intime)
    @pastbooking = Booking.where("room_no = ? AND intime < ?",roomid,DateTime.current).order(intime: :desc)
    @deletedbooking = Deletedbooking.where("room_no = ?",roomid).order(intime: :desc)
  end

  def bookingMailer

  end
#Method for sending emails.
  def send_mail

    user = User.find_by_id(@booking.userid)
    room = Room.find_by_id(@booking.room_no)

    bookingInfo = BookingInfo.new
    bookingInfo.name =user.name
    bookingInfo.userEmail =user.email
    bookingInfo.location =room.location
    bookingInfo.roomNumber = room.id
    bookingInfo.startTime = @booking.intime.strftime('%H:%M')
    bookingInfo.date = @booking.intime.strftime('%m/%d/%Y')
    bookingInfo.email = params[:email]
    bookingInfo.duration = '2 hours'
    if(UserMailer.booking_intimation(bookingInfo).deliver)
      render :json =>{:message => "success"}
      return
    else
      return render :json =>{:message => "failure"}
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_booking
    @booking = Booking.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def booking_params
    params.require(:booking).permit(:userid, :room_no, :intime)
  end

end
