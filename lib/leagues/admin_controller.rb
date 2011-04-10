module Leagues
  module AdminController
    def index
      @leagues = League.all
    end

    def show
      @league = League.find(params[:id])
    end

    def new
      @league = League.new
    end

    def edit
      @league = League.find(params[:id])
    end

    def create
      @league = League.new(params[:league])

      if @league.save
        redirect_to :action => :index, :notice => 'League was successfully created.'
      else
        render :action => "new"
      end
    end

    def update
      @league = League.find(params[:id])

      if @league.update_attributes(params[:league])
        redirect_to :action => :index, :notice => 'League was successfully updated.'
      else
        render :action => "edit"
      end
    end

    def destroy
      @league = League.find(params[:id])
      @league.destroy

      redirect_to :action => :index
    end
  end
end