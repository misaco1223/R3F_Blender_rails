class Api::BoardsController < ApplicationController
  def create
    board = Board.new(
      user_id: current_user.id,
      cut_cube_id: board_params[:cut_cube_id],
      question: board_params[:question],
      answer: board_params[:answer],
      explanation: board_params[:explanation],
      published: board_params[:published]
    )
    if board.save
      if params[:tags].present?
        params[:tags].each do |tag_name|
          tag = Tag.find_by(name: tag_name)
          if tag
            board_tag = BoardTag.create(board_id:board.id, tag_id:tag.id)
          end
        end
      end
      render json: { message: "Board作成完了", board_id: board.id }, status: :ok
    else
      render json: { message: "登録に失敗しました", errors: board.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def my_boards_index
    boards = current_user.boards
      .joins(:cut_cube)
      .includes(board_tags: :tag)
      .order(created_at: :desc)
    
    boards_data =
      {
        board_ids: boards.map { |board| board.id },
        cut_points: boards.map { |board| JSON.parse(board.cut_cube.cut_points)},
        questions: boards.map { |board| board.question },
        created_at: boards.map { |board| board.created_at },
        published: boards.map { |board| board.published },
        tags: boards.map { |board| board.board_tags.map { |board_tag| board_tag.tag.name } }
      }
    render json: { boards: boards_data }, status: :ok
  end

  def index
    boards = Board.where(published: true)
      .joins(:user, :cut_cube)
      .includes(board_tags: :tag)
      .order(created_at: :desc)
    
    if params[:tag_id].present?
      boards = boards.joins(board_tags: :tag).where(board_tags: { tag_id: params[:tag_id] })
    elsif params[:filter].present?
      if params[:filter] === "tag"
        boards = boards.joins(board_tags: :tag)
      end
    end

    boards_data =
      {
        user_names: boards.map { |board| board.user.name },
        board_ids: boards.map { |board| board.id },
        cut_points: boards.map { |board| JSON.parse(board.cut_cube.cut_points)},
        questions: boards.map { |board| board.question },
        created_at: boards.map { |board| board.created_at },
        tags: boards.map { |board| board.board_tags
                                    .includes(:tag)  # tagを含める
                                    .sort_by { |board_tag| board_tag.created_at }
                                    .map { |board_tag| board_tag.tag.name } }
      }
      
    render json: { boards: boards_data }, status: :ok
  end

  # 公開Boardの情報を取得
  def show
    board = Board
      .joins(:user, :cut_cube)
      .includes(board_tags: :tag)
      .find_by(id: params[:id])

    if board.present?
      board_data = {
        user_name: board.user.name,
        glb_url: url_for(board.cut_cube.gltf_file),
        cut_points: JSON.parse(board.cut_cube.cut_points),
        question: board.question,
        answer: board.answer,
        explanation: board.explanation,
        created_at: board.created_at,
        is_owner: board.user_id == current_user.id,
        published: board.published,
        tags: board.board_tags.map{ |board_tag| board_tag.tag.name }
      }
      render json: { board: board_data}, status: :ok
    end
  end

  def update
    board = current_user.boards.find_by(id: params[:id])

    if board.nil?
      return render json: { error: 'Board not found' }, status: :not_found
    end

    if board.update(board_update_params)
      if params[:tags].present?
        params[:tags].each do |tag_name|
          tag = Tag.find_by(name: tag_name)
          if tag
            unless board.board_tags.exists?(tag_id: tag.id)
              BoardTag.create(board_id: board.id, tag_id: tag.id)
            end
          end
        end

        board.board_tags.each do |board_tag|
          unless params[:tags].include?(board_tag.tag.name)
            board_tag.destroy
          end
        end
      end

      render json: { status: "success", message: 'Board updated successfully' }, status: :ok
    else
      render json: { error: 'Board not found' }, status: :not_found
    end
  end

  def destroy
    board = current_user.boards.find_by(id: params[:id])

    if board.present?
      board.destroy
      render json: { status: "success", message: 'Board deleted successfully' }, status: :ok
    else
      render json: { error: 'Board not found' }, status: :not_found
    end
  end
      
  private

  def board_params
    params.require(:board).permit(:cut_cube_id, :question, :answer, :explanation, :published)
  end

  def board_update_params
    params.require(:board).permit(:question, :answer, :explanation, :published)
  end
end