class MatchesController < ApplicationController
  def new
    @match = Match.new
    2.times do
      team = @match.teams.build
    end
  end

  def matches_good_conditions
    if (@match.teams.first.player_id.nil? || @match.teams.last.player_id.nil?)
      flash[:danger] = 'Veuillez indiquer deux joueurs !'
      return false
    end
    if (@match.teams.first.player_id == @match.teams.last.player_id)
      flash[:danger] = 'Veuillez indiquer deux joueurs différents !'
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

    return true
  end

  def points_conditions
    if ((@match.teams.first.score > @match.teams.last.score) && !@match.prolongations)
        flash[:notice] = "J1 a gagné"
        @playerone.points += 3
        @playerone.win += 1
        @playerone.save
        @playertwo.lose += 1
        @playertwo.save

    elsif ((@match.teams.first.score < @match.teams.last.score) && !@match.prolongations)
        flash[:notice] = "J2 a gagné"
        @playertwo.points += 3
        @playertwo.win += 1
        @playertwo.save
        @playerone.lose += 1
        @playerone.save

    elsif @match.prolongations && (@match.teams.first.score > @match.teams.last.score)
        flash[:notice] = "J1 a gagné après prolongations"
        @playerone.points += 2
        @playerone.win_prol += 1
        @playerone.save
        @playertwo.lose_prol += 1
        @playertwo.save

    elsif @match.prolongations && (@match.teams.first.score < @match.teams.last.score)
        flash[:notice] = "J2 a gagné après prolongations"
        @playertwo.points += 2
        @playertwo.win_prol += 1
        @playertwo.save
        @playerone.lose_prol += 1
        @playerone.save

    elsif (@match.teams.first.score == @match.teams.last.score) && (@match.teams.first.prol_score > @match.teams.last.prol_score)
        flash[:notice] = "J1 a gagné aux tirs au buts."
        @match.prolongations = true
        @match.save
        @playerone.points += 1
        @playerone.win_peno += 1
        @playerone.save
        @playertwo.lose_peno += 1
        @playertwo.save

    elsif (@match.teams.first.score == @match.teams.last.score) && (@match.teams.first.prol_score < @match.teams.last.prol_score)
        flash[:notice] = "J2 a gagné aux tirs au buts."
        @match.prolongations = true
        @match.save
        @playertwo.points += 1
        @playertwo.win_peno += 1
        @playertwo.save
        @playerone.lose_peno += 1
        @playerone.save

    else
        p "Autre chose"
    end
  end

  def matches_update_remove_points
    if ((@home_team_old_score > @visiting_team_old_score ) && !@match_prol_old)
        @playerone.points -= 3
        p "Retrait points J1 a gagné"
        @playerone.win -= 1
        @playerone.save
        @playertwo.lose -= 1
        @playertwo.save

    elsif ((@home_team_old_score < @visiting_team_old_score ) && !@match_prol_old)
        @playertwo.points -= 3
        p "Retrait points J2 a gagné"
        @playertwo.win -= 1
        @playertwo.save
        @playerone.lose -= 1
        @playerone.save

    elsif @match_prol_old && (@home_team_old_score > @visiting_team_old_score )
        @playerone.points -= 2
        p "Retrait points : J1 a gagné après prolongations"
        @playerone.win_prol -= 1
        @playerone.save
        @playertwo.lose_prol -= 1
        @playertwo.save

    elsif @match_prol_old && (@home_team_old_score < @visiting_team_old_score )
        @playertwo.points -= 2
        flash[:notice] = "Retrait points : J2 a gagné après prolongations"
        @playertwo.win_prol -= 1
        @playertwo.save
        @playerone.lose_prol -= 1
        @playerone.save

    elsif (@home_team_old_score == @visiting_team_old_score ) && (@home_team_old_prol_score > @visiting_team_old_prol_score)
        @playerone.points -= 1
        flash[:notice] = "Retrait points : J1 a gagné aux tirs au buts."
        @playerone.win_peno -= 1
        @playerone.save
        @playertwo.lose_peno -= 1
        @playertwo.save

    elsif (@home_team_old_score == @visiting_team_old_score ) && (@home_team_old_prol_score < @visiting_team_old_prol_score)
        @playertwo.points -= 1
        flash[:notice] = "Retrait points : J2 a gagné aux tirs au buts."
        @playertwo.win_peno -= 1
        @playertwo.save
        @playerone.lose_peno -= 1
        @playerone.save

    else
        p "Old : Autre chose"
    end
  end

  def create
    @match = Match.new(match_params)
    if matches_good_conditions

    @playerone = Player.find(@match.teams.first.player_id)
    @playertwo = Player.find(@match.teams.last.player_id)

        if @match.save
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
    @home_team_old_score = @match.teams.first.score
    @visiting_team_old_score = @match.teams.last.score
    @home_team_old_prol_score = @match.teams.first.prol_score
    @visiting_team_old_prol_score = @match.teams.last.prol_score
    @match_prol_old = @match.prolongations

    if @match.update(match_params)
      #Retraits points sur anciens reusltats
      matches_update_remove_points()
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

  def destroy
    @match = Match.find(params[:id])
    @playerone = Player.find(@match.teams.first.player_id)
    @playertwo = Player.find(@match.teams.last.player_id)
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
    params.require(:match).permit(:id, :prolongations,
      teams_attributes: [:id, :score, :prol_score, :club_id, :match_id, :player_id],
      )
  end
end
