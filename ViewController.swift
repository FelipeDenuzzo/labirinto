import UIKit

class ViewController: UIViewController {

    var dificuldadeSlider: UISlider!
    var confirmarButton: UIButton!
    var tamanhoCelula: CGFloat = 40.0
    var larguraLabirinto = 10
    var alturaLabirinto = 10

    var labirinto: [[Int]] = []
    var jogadorPosicao: (x: Int, y: Int) = (1, 1)
    var jogadorView: UIView!
    var scrollView: UIScrollView!
    var labirintoView: UIView!
    var caminhoPercorrido: Set<(Int, Int)> = [] // Rastreia células visitadas

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Adiciona o slider de dificuldade
        configurarDificuldadeSlider()
        // Adiciona o botão de confirmação
        configurarConfirmarButton()
    }

    func configurarDificuldadeSlider() {
        dificuldadeSlider = UISlider(frame: CGRect(x: 50, y: 100, width: 300, height: 20))
        dificuldadeSlider.minimumValue = 5
        dificuldadeSlider.maximumValue = 30
        dificuldadeSlider.value = Float(larguraLabirinto)
        view.addSubview(dificuldadeSlider)
    }

    func configurarConfirmarButton() {
        confirmarButton = UIButton(frame: CGRect(x: 50, y: 150, width: 300, height: 50))
        confirmarButton.setTitle("Confirmar Dificuldade", for: .normal)
        confirmarButton.setTitleColor(.white, for: .normal)
        confirmarButton.backgroundColor = .blue
        confirmarButton.addTarget(self, action: #selector(confirmarDificuldade), for: .touchUpInside)
        view.addSubview(confirmarButton)
    }

    @objc func confirmarDificuldade() {
        larguraLabirinto = Int(dificuldadeSlider.value)
        alturaLabirinto = Int(dificuldadeSlider.value)
        atualizarLabirinto()
        dificuldadeSlider.isHidden = true
        confirmarButton.isHidden = true
    }

    func atualizarLabirinto() {
        labirintoView?.removeFromSuperview()
        jogadorView?.removeFromSuperview()

        labirinto = gerarLabirinto(largura: larguraLabirinto, altura: alturaLabirinto)
        configurarScrollView()
        criarLabirinto()
        configurarJogador()
        adicionarGestos()
        adicionarBotaoReiniciar()
    }
}

extension ViewController {
    func configurarScrollView() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.backgroundColor = .white
        scrollView.contentSize = CGSize(
            width: tamanhoCelula * CGFloat(larguraLabirinto * 2 + 1),
            height: tamanhoCelula * CGFloat(alturaLabirinto * 2 + 1)
        )
        view.addSubview(scrollView)

        labirintoView = UIView(frame: CGRect(
            x: 0,
            y: 0,
            width: tamanhoCelula * CGFloat(larguraLabirinto * 2 + 1),
            height: tamanhoCelula * CGFloat(alturaLabirinto * 2 + 1)
        ))
        labirintoView.backgroundColor = .black
        scrollView.addSubview(labirintoView)
    }

    func gerarLabirinto(largura: Int, altura: Int) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 1, count: largura * 2 + 1), count: altura * 2 + 1)

        func abrirCaminho(x: Int, y: Int) {
            grid[y][x] = 0
        }

        func vizinhosValidos(x: Int, y: Int) -> [(Int, Int)] {
            var vizinhos: [(Int, Int)] = []
            let direcoes = [(0, -2), (0, 2), (-2, 0), (2, 0)]

            for (dx, dy) in direcoes {
                let nx = x + dx
                let ny = y + dy
                if nx > 0, ny > 0, nx < largura * 2, ny < altura * 2, grid[ny][nx] == 1 {
                    vizinhos.append((nx, ny))
                }
            }

            return vizinhos
        }

        func removerParedeEntre(x1: Int, y1: Int, x2: Int, y2: Int) {
            let mx = (x1 + x2) / 2
            let my = (y1 + y2) / 2
            grid[my][mx] = 0
        }

        var stack: [(Int, Int)] = [(1, 1)]
        abrirCaminho(x: 1, y: 1)

        while !stack.isEmpty {
            let current = stack.last!
            let vizinhos = vizinhosValidos(x: current.0, y: current.1)

            if !vizinhos.isEmpty {
                let escolhido = vizinhos.randomElement()!
                removerParedeEntre(x1: current.0, y1: current.1, x2: escolhido.0, y2: escolhido.1)
                abrirCaminho(x: escolhido.0, y: escolhido.1)
                stack.append(escolhido)
            } else {
                stack.removeLast()
            }
        }

        grid[1][1] = 0 // Entrada
        grid[altura * 2 - 1][largura * 2 - 1] = 0 // Saída

        return grid
    }

    func criarLabirinto() {
        for y in 0..<labirinto.count {
            for x in 0..<labirinto[y].count {
                let bloco = UIView(frame: CGRect(
                    x: CGFloat(x) * tamanhoCelula,
                    y: CGFloat(y) * tamanhoCelula,
                    width: tamanhoCelula,
                    height: tamanhoCelula
                ))
                bloco.backgroundColor = labirinto[y][x] == 1 ? .red : .white
                bloco.tag = y * labirinto[0].count + x // Identifica cada célula
                labirintoView.addSubview(bloco)
            }
        }
        adicionarEntradaSaida()
    }

    func adicionarEntradaSaida() {
        let entrada = UIView(frame: CGRect(x: tamanhoCelula, y: tamanhoCelula, width: tamanhoCelula, height: tamanhoCelula))
        entrada.backgroundColor = .green
        labirintoView.addSubview(entrada)

        let saida = UIView(frame: CGRect(
            x: CGFloat(labirinto[0].count - 2) * tamanhoCelula,
            y: CGFloat(labirinto.count - 2) * tamanhoCelula,
            width: tamanhoCelula,
            height: tamanhoCelula
        ))
        saida.backgroundColor = .blue
        labirintoView.addSubview(saida)
    }
}

extension ViewController {
    func configurarJogador() {
        jogadorView = UIView(frame: CGRect(x: tamanhoCelula, y: tamanhoCelula, width: tamanhoCelula, height: tamanhoCelula))
        jogadorView.backgroundColor = .yellow
        labirintoView.addSubview(jogadorView)

        // Marca a célula inicial como percorrida
        caminhoPercorrido.insert((1, 1))
    }

    func adicionarGestos() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        labirintoView.addGestureRecognizer(tapGesture)
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: labirintoView)
        let gridX = Int(location.x / tamanhoCelula)
        let gridY = Int(location.y / tamanhoCelula)

        guard gridX >= 0, gridY >= 0, gridX < labirinto[0].count, gridY < labirinto.count else { return }

        if labirinto[gridY][gridX] == 0, pontosAdjacentes(jogadorPosicao, (gridX, gridY)) {
            atualizarJogadorPosicao(gridX: gridX, gridY: gridY)
        }
    }

    func pontosAdjacentes(_ p1: (Int, Int), _ p2: (Int, Int)) -> Bool {
        let dx = abs(p1.0 - p2.0)
        let dy = abs(p1.1 - p2.1)
        return (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
    }

    func atualizarJogadorPosicao(gridX: Int, gridY: Int) {
        if caminhoPercorrido.contains((gridX, gridY)) {
            // Desfaz o caminho
            caminhoPercorrido.remove((gridX, gridY))
            atualizarCelula(gridX: gridX, gridY: gridY, cor: .white)
        } else {
            // Marca nova célula como percorrida
            caminhoPercorrido.insert((gridX, gridY))
            atualizarCelula(gridX: gridX, gridY: gridY, cor: .gray)
        }

        jogadorPosicao = (gridX, gridY)
        jogadorView.frame.origin = CGPoint(
            x: CGFloat(gridX) * tamanhoCelula,
            y: CGFloat(gridY) * tamanhoCelula
        )
    }

    func atualizarCelula(gridX: Int, gridY: Int, cor: UIColor) {
        let tag = gridY * labirinto[0].count + gridX
        if let celula = labirintoView.viewWithTag(tag) {
            celula.backgroundColor = cor
        }
    }

    func adicionarBotaoReiniciar() {
        let reiniciarButton = UIButton(frame: CGRect(
            x: 50,
            y: Int(scrollView.frame.maxY) + 10, // Ajusta para ficar abaixo do labirinto
            width: 300,
            height: 50
        ))
        reiniciarButton.setTitle("Reiniciar Jogo", for: .normal)
        reiniciarButton.setTitleColor(.white, for: .normal)
        reiniciarButton.backgroundColor = .red
        reiniciarButton.addTarget(self, action: #selector(reiniciarJogo), for: .touchUpInside)
        view.addSubview(reiniciarButton)
    }

    @objc func reiniciarJogo() {
        dificuldadeSlider.isHidden = false
        confirmarButton.isHidden = false
        labirintoView?.removeFromSuperview()
        scrollView?.removeFromSuperview()
        jogadorView?.removeFromSuperview()
        caminhoPercorrido.removeAll()

        larguraLabirinto = 10
        alturaLabirinto = 10
        tamanhoCelula = 40.0
    }
}

extension ViewController {
    func mostrarMensagemVitoria() {
        let alert = UIAlertController(title: "Parabéns!", message: "Você encontrou a saída!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.adicionarBotaoReiniciar()
        })
        present(alert, animated: true)
    }
}
