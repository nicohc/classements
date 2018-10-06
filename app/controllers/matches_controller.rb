class MatchesController < ApplicationController

  def new
    @match = Match.new
    2.times do
      team = @match.teams.build
    end
  end

  def matches_good_conditions

    if @match.tournament_id.nil?
      flash[:danger] = 'Veuillez indiquer une compétition !'
      return false
    end

    if @match.teams.empty?
      flash[:danger] = 'Veuillez indiquer deux joueurs !'
      return false
    end
    if (@match.teams.first.player_id.nil? || @match.teams.last.player_id.nil?)
      flash[:danger] = 'Veuillez indiquer deux joueurs !'
      return false
    end
    if (@match.teams.first.player_id == @match.teams.last.player_id)
      flash[:danger] = 'Veuillez indiquer deux joueurs différents !'
      return false
    end

    if !@match.tournament.players.ids.include?(@match.teams.first.player_id || @match.teams.last.player_id)
      flash[:danger] = 'Veuillez indiquer deux joueurs inscrits à cette compétiton !'
      return false
    end

    if ((@match.teams.first.score == @match.teams.last.score) && (@match.teams.first.prol_score == @match.teams.last.prol_score))
      flash[:danger] = 'Match nul + Scores aux penaties identiques. Impossible de donner un vainqueur !'
      return false
    end
    if ((@match.teams.first.score == @match.teams.last.score) && @match.teams.first.prol_score.nil?)
      flash[:danger] = 'Match nul : Score aux penalties incomplets.'
      return false
    end

    if (@match.teams.first.club_id.nil? || @match.teams.last.club_id.nil?)
      flash[:danger] = 'Veuillez indiquer un club pour chaque équipe !'
      return false
    end



    return true
  end


  def winning_conditions
      if ((@match.teams.first.score > @match.teams.last.score) && !@match.prolongations)
          flash[:notice] = "J1 a gagné"
          @match.teams.first[:status] = "winner"
          @match.teams.last[:status] = "loser"
      elsif ((@match.teams.first.score < @match.teams.last.score) && !@match.prolongations)
          flash[:notice] = "J2 a gagné"
          @match.teams.first[:status] = "loser"
          @match.teams.last[:status] = "winner"

      elsif @match.prolongations && (@match.teams.first.score > @match.teams.last.score)
          flash[:notice] = "J1 a gagné après prolongations"
          @match.teams.first.status = "winner"
          @match.teams.last.status = "loser"
      elsif @match.prolongations && (@match.teams.first.score < @match.teams.last.score)
          flash[:notice] = "J2 a gagné après prolongations"
          @match.teams.first.status = "loser"
          @match.teams.last.status = "winner"
      elsif (@match.teams.first.score == @match.teams.last.score) && (@match.teams.first.prol_score > @match.teams.last.prol_score)
          flash[:notice] = "J1 a gagné aux tirs au buts."
          @match.prolongations = true
          @match.teams.first.status = "winner"
          @match.teams.last.status = "loser"
      elsif (@match.teams.first.score == @match.teams.last.score) && (@match.teams.first.prol_score < @match.teams.last.prol_score)
          flash[:notice] = "J2 a gagné aux tirs au buts."
          @match.prolongations = true
          @match.teams.first.status = "loser"
          @match.teams.last.status = "winner"

      end
  end

  def update_winning_conditions
      if ((@match.teams.first.score > @match.teams.last.score) && !@match.prolongations)
          flash[:notice] = "J1 a gagné"
          @match.teams.first.update_columns(status: "winner")
          @match.teams.last.update_columns(status: "loser")
      elsif ((@match.teams.first.score < @match.teams.last.score) && !@match.prolongations)
          flash[:notice] = "J2 a gagné"
          @match.teams.first.update_columns(status: "loser")
          @match.teams.last.update_columns(status: "winner")

      elsif @match.prolongations && (@match.teams.first.score > @match.teams.last.score)
          flash[:notice] = "J1 a gagné après prolongations"
          @match.teams.first.update_columns(status: "winner")
          @match.teams.last.update_columns(status: "loser")
      elsif @match.prolongations && (@match.teams.first.score < @match.teams.last.score)
          flash[:notice] = "J2 a gagné après prolongations"
          @match.teams.first.update_columns(status: "loser")
          @match.teams.last.update_columns(status: "winner")
      elsif (@match.teams.first.score == @match.teams.last.score) && (@match.teams.first.prol_score > @match.teams.last.prol_score)
          flash[:notice] = "J1 a gagné aux tirs au buts."
          @match.prolongations = true
          @match.teams.first.update_columns(status: "winner")
          @match.teams.last.update_columns(status: "loser")
          @match.save
      elsif (@match.teams.first.score == @match.teams.last.score) && (@match.teams.first.prol_score < @match.teams.last.prol_score)
          flash[:notice] = "J2 a gagné aux tirs au buts."
          @match.prolongations = true
          @match.teams.first.update_columns(status: "loser")
          @match.teams.last.update_columns(status: "winner")
          @match.save
      end
  end

  def points_conditions
    if ((@match.teams.first.score > @match.teams.last.score) && !@match.prolongations)
        flash[:notice] = "+#{@match.tournament.win_regular_points} points pour J1"
        @seasonone.points += @match.tournament.win_regular_points
        @seasonone.win += 1
        @seasonone.save
        @seasontwo.points += @match.tournament.lose_regular_points
        @seasontwo.lose += 1
        @seasontwo.save

    elsif ((@match.teams.first.score < @match.teams.last.score) && !@match.prolongations)
        flash[:notice] = "+#{@match.tournament.win_regular_points} points pour J2"
        @seasontwo.points += @match.tournament.win_regular_points
        @seasontwo.win += 1
        @seasontwo.save
        @seasonone.points += @match.tournament.lose_regular_points
        @seasonone.lose += 1
        @seasonone.save

    elsif @match.prolongations && (@match.teams.first.score > @match.teams.last.score)
        flash[:notice] = "+#{@match.tournament.win_prol_points} points pour J1"
        @seasonone.points += @match.tournament.win_prol_points
        @seasonone.win_prol += 1
        @seasonone.save
        @seasontwo.points += @match.tournament.lose_prol_points
        @seasontwo.lose_prol += 1
        @seasontwo.save

    elsif @match.prolongations && (@match.teams.first.score < @match.teams.last.score)
        flash[:notice] = "+#{@match.tournament.win_prol_points} points pour J2"
        @seasontwo.points += @match.tournament.win_prol_points
        @seasontwo.win_prol += 1
        @seasontwo.save
        @seasonone.points += @match.tournament.lose_prol_points
        @seasonone.lose_prol += 1
        @seasonone.save

    elsif (@match.teams.first.score == @match.teams.last.score) && (@match.teams.first.prol_score > @match.teams.last.prol_score)
        flash[:notice] = "+#{@match.tournament.win_peno_points} point pour J1"
        @seasonone.points += @match.tournament.win_peno_points
        @seasonone.win_peno += 1
        @seasonone.save
        @seasontwo.points += @match.tournament.lose_peno_points
        @seasontwo.lose_peno += 1
        @seasontwo.save

    elsif (@match.teams.first.score == @match.teams.last.score) && (@match.teams.first.prol_score < @match.teams.last.prol_score)
        flash[:notice] = "+#{@match.tournament.win_peno_points} point pour J2"
        @seasontwo.points += @match.tournament.win_peno_points
        @seasontwo.win_peno += 1
        @seasontwo.save
        @seasonone.points += @match.tournament.lose_peno_points
        @seasonone.lose_peno += 1
        @seasonone.save

    else
        p "Autre chose"
    end
  end

  def matches_update_remove_points
    if ((@home_team_old_score > @visiting_team_old_score ) && !@match_prol_old)
        p "Retrait points J1 a gagné"
        flash[:notice] = "+#{@match.tournament.win_regular_points} points pour J1"
        @seasonone.points -= @match.tournament.win_regular_points
        @seasonone.win -= 1
        @seasonone.save
        @seasontwo.points -= @match.tournament.lose_regular_points
        @seasontwo.lose -= 1
        @seasontwo.save

    elsif ((@home_team_old_score < @visiting_team_old_score ) && !@match_prol_old)
        p "Retrait points J2 a gagné"
        flash[:notice] = "-#{@match.tournament.win_regular_points} points pour J2"
        @seasontwo.points -= @match.tournament.win_regular_points
        @seasontwo.win -= 1
        @seasontwo.save
        @seasonone.points -= @match.tournament.lose_regular_points
        @seasonone.lose -= 1
        @seasonone.save

    elsif @match_prol_old && (@home_team_old_score > @visiting_team_old_score )
        @seasonone.points -= 2
        p "Retrait points : J1 a gagné après prolongations"
        @seasonone.win_prol -= 1
        @seasonone.save
        @seasontwo.lose_prol -= 1
        @seasontwo.save

    elsif @match_prol_old && (@home_team_old_score < @visiting_team_old_score )
        @seasontwo.points -= 2
        flash[:notice] = "Retrait points : J2 a gagné après prolongations"
        @seasontwo.win_prol -= 1
        @seasontwo.save
        @seasonone.lose_prol -= 1
        @seasonone.save

    elsif (@home_team_old_score == @visiting_team_old_score ) && (@home_team_old_prol_score > @visiting_team_old_prol_score)
        @seasonone.points -= 1
        flash[:notice] = "Retrait points : J1 a gagné aux tirs au buts."
        @seasonone.win_peno -= 1
        @seasonone.save
        @seasontwo.lose_peno -= 1
        @seasontwo.save

    elsif (@home_team_old_score == @visiting_team_old_score ) && (@home_team_old_prol_score < @visiting_team_old_prol_score)
        @seasontwo.points -= 1
        flash[:notice] = "Retrait points : J2 a gagné aux tirs au buts."
        @seasontwo.win_peno -= 1
        @seasontwo.save
        @seasonone.lose_peno -= 1
        @seasonone.save

    else
        p "Old : Autre chose"
    end
  end


    def image_illustration
      if @match.teams.first.status == "winner"
        @match.image_une_url = @match.teams.first.club.image_url
        @match.save
      else
        @match.image_une_url = @match.teams.last.club.image_url
        @match.save
      end
    end


  def create
    @match = Match.new(match_params)
    if matches_good_conditions()
    @playerone = Player.find(@match.teams.first.player_id)
    @playertwo = Player.find(@match.teams.last.player_id)
    @seasonone = Season.where(["player_id=? and tournament_id=?", @playerone, @match.tournament_id]).first
    @seasontwo = Season.where(["player_id=? and tournament_id=?", @playertwo, @match.tournament_id]).first

    winning_conditions()
        if @match.save
          @match.teams.first.season_id = @seasonone.id
          @match.teams.second.season_id = @seasontwo.id
          @match.save

          image_illustration()
          points_conditions()
          flash[:success] = "Votre match a bien été créé !"
          redirect_to @match
        end
    else
      redirect_to new_match_path
      p "Une erreur existe, veuillez recommencer."
    end
  end


  def edit
    @match = Match.find(params[:id])
  end

  def update
    @match = Match.find(params[:id])
    @playerone = Player.find(@match.teams.first.player_id)
    @playertwo = Player.find(@match.teams.last.player_id)
    @seasonone = Season.where(["player_id=? and tournament_id=?", @playerone, @match.tournament_id]).first
    @seasontwo = Season.where(["player_id=? and tournament_id=?", @playertwo, @match.tournament_id]).first
    @home_team_old_score = @match.teams.first.score
    @visiting_team_old_score = @match.teams.last.score
    @home_team_old_prol_score = @match.teams.first.prol_score
    @visiting_team_old_prol_score = @match.teams.last.prol_score
    @match_prol_old = @match.prolongations

    if @match.update(match_params)
      #Retraits points sur anciens resultats
      matches_update_remove_points()
      update_winning_conditions()
      #Nouveaux resultats
      points_conditions()

      redirect_to root_path
    else
      render :action => 'edit'
    end

  end

  def show
    @match = Match.find(params[:id])
    @home_team = Match.find(params[:id]).teams.first
    @visiting_team = Match.find(params[:id]).teams.last
    @playerone = Player.find(@match.teams.first.player_id)
    @playertwo = Player.find(@match.teams.last.player_id)
  end

  def randomiser
    clubs = Club.all
    mode = ["Normal", "Sans règle", "Survie", "Distance", "Premier à...", "Têtes et volées" ]
    @modealeatoire = mode.sample(1)
    @club_alea1 = clubs.sample.name
    @club_alea2 = clubs.sample.name
  end

  def destroy
    @match = Match.find(params[:id])
    @playerone = Player.find(@match.teams.first.player_id)
    @playertwo = Player.find(@match.teams.last.player_id)
    @seasonone = Season.where(["player_id=? and tournament_id=?", @playerone, @match.tournament_id]).first
    @seasontwo = Season.where(["player_id=? and tournament_id=?", @playertwo, @match.tournament_id]).first
    @home_team_old_score = @match.teams.first.score
    @visiting_team_old_score = @match.teams.last.score
    @home_team_old_prol_score = @match.teams.first.prol_score
    @visiting_team_old_prol_score = @match.teams.last.prol_score
    @match_prol_old = @match.prolongations

    #Retraits points sur anciens reusltats
    matches_update_remove_points()

    @match.destroy
    redirect_to root_path
  end






  private
  def match_params
    params.require(:match).permit(:id, :mode, :prolongations, :image_une_url, :tournament_id,
      teams_attributes: [:id, :score, :prol_score, :club_id, :match_id, :player_id, :season_id],
      )
  end
end
