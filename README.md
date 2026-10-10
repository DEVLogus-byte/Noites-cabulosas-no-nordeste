# Noites Cabulosas (Demo) — Godot 4.3+

Top-down 2D em estilo GBA (resolução 240x160, escala inteira), furtividade num casarão invadido pelos capangas do Lampião.
Tudo é desenhado/sonorizado por código: **não há assets externos**.

## Como abrir
1. Abra o Godot 4.3 ou mais novo → *Import* → selecione `project.godot`.
2. Aperte **F5**.

## Controles
| Ação | Teclado | Controle |
|---|---|---|
| Mover | WASD / Setas | D-pad / analógico |
| Correr (faz barulho!) | Shift ou X | B |
| Interagir / esconder-se / sair | E, Z ou Espaço | A |
| Confirmar menus | Enter | Start / A |
| Voltar ao título | Esc | |

## Como jogar
- Ache a **chave**, abra a **porta trancada** — e veja o que acontece com o chão da sala.
- Os capangas (chapéu de couro, óculos redondos, cartucheira e rifle) têm **cone de visão** (aparece no chão), **audição** (correr chama atenção) e perseguem você.
- Fique perto de **mesas e camas** e aperte **E** para se esconder embaixo. Não dá para se esconder se
  algum capanga está te vendo ou te perseguindo de perto.
- Fase 2 (porão): ache a chave, abra o portão e suba a escada → **FIM DA DEMO**.

## Estrutura
- `scripts/level_data.gd` — **mapas, móveis e rotas dos monstros** (edite aqui para criar fases).
- `scripts/level.gd` — lógica da fase (colisão, esconder, porta, chão que quebra, câmera, escuridão).
- `scripts/monster.gd` — IA e sprite dos capangas (patrulha, investigar, perseguir, procurar). Constantes no topo para balancear.
- `scripts/player.gd`, `tile_layer.gd`, `furniture.gd`, `overlay.gd`, `hud.gd`, `screens.gd`, `pixel_font.gd`, `game.gd`, `main.gd`.

## Ajustes rápidos
- Dificuldade: `VISION`, `HALF_FOV`, `NOISE_RADIUS`, `CHASE_SPEED` em `monster.gd`; `WALK`/`RUN` em `player.gd`.
- Raio da lanterna: `radius` em `level.gd` (`_update_darkness`).
