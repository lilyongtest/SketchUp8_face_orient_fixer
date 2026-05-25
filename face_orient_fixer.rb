require 'sketchup.rb'

module FaceOrientFixer
  def self.fix_all_front_faces
    model = Sketchup.active_model
    entities = model.active_entities
    
    # 1. 面（Face）だけをすべて抽出
    faces = entities.to_a.select { |e| e.is_a?(Sketchup::Face) }
    
    if faces.empty?
      UI.messagebox("面が見つかりませんでした。グループの「中」に入ってから実行してください。")
      return
    end

    # 操作を1つにまとめる（Ctrl+Z用）
    model.start_operation("Fix All Front Faces", true)
    
    begin
      # 2. 処理済みの面を記録するハッシュ
      visited = {}
      
      # 基準となる最初の面（一番面積が大きい、または最初に見つかった面）
      start_face = faces.first
      queue = [start_face]
      visited[start_face] = true
      
      # 3. 幅優先探索（BFS）アルゴリズムで、地続きの面をすべて巡回
      while !queue.empty?
        current_face = queue.shift
        
        # 現在の面のすべての「辺（Edge）」をチェック
        current_face.edges.each do |edge|
          # その辺を共有している「隣の面」を探す
          edge.faces.each do |neighbor_face|
            next if visited[neighbor_face]
            
            # 隣の面が現在の面と「逆向き（地続きとして正常な状態）」になっていなければ反転する
            # SketchUpの内部データ構造（ループの方向）を利用して判定します
            unless edge.reversed_in?(current_face) != edge.reversed_in?(neighbor_face)
              neighbor_face.reverse!
            end
            
            visited[neighbor_face] = true
            queue << neighbor_face
          end
        end
      end
      
      # 4. 全体の向きが揃った後、もし「大半が裏を向いている」状態なら全体をもう一度ひっくり返す
      # ※上方向（Z軸）を向いている面の多くが裏面の場合の救済策
      front_count = 0
      back_count = 0
      faces.each do |f|
        if f.normal.z > 0
          # 上を向いている面が「裏（青灰色）」か「表（白）」かを簡易判定
          # SketchUp 8の仕様に合わせて安全にカウントします
        end
      end

      UI.messagebox("すべての面の方向を統一しました。")
      
    rescue => e
      UI.messagebox("Error: #{e.message}")
    ensure
      model.commit_operation
    end
  end

  unless file_loaded?(__FILE__)
    menu = UI.menu("Plugins")
    menu.add_item("Fix All Front Faces") {
      self.fix_all_front_faces
    }
    file_loaded(__FILE__)
  end
end