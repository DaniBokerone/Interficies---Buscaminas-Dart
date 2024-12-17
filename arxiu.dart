import 'dart:io';
import 'dart:math';

const int files = 6;
const int columnes = 10;
const int mines = 8;

// Representació del tauler
List<List<String>> tauler =
    List.generate(files, (_) => List.generate(columnes, (_) => '·'));
List<List<bool>> minesTauler =
    List.generate(files, (_) => List.generate(columnes, (_) => false));
List<List<bool>> descobert =
    List.generate(files, (_) => List.generate(columnes, (_) => false));
List<List<bool>> bandera =
    List.generate(files, (_) => List.generate(columnes, (_) => false));
bool mostrarTrampes = false;
int tirades = 0;

void main() {
  // Inicialitza les mines
  inicialitzarMines();

  while (true) {
    mostrarTauler();
    print('----------------------------------------------------------------------');
    stdout.write('Escriu una comanda: ');
    String? input = stdin.readLineSync();

    if (input == null || input.isEmpty) {
      print('Comanda invàlida.');
      continue;
    }

    if (input.toLowerCase() == 'help' || input.toLowerCase() == 'ajuda') {
      mostrarAjuda();
      continue;
    }

    if (input.toLowerCase() == 'trampes' || input.toLowerCase() == 'cheat') {
      mostrarTrampes = !mostrarTrampes;
      continue;
    }

    bool posarBandera = input.contains('flag') || input.contains('bandera');
    String posicio = input.split(' ')[0];

    if (posicio.length < 2 || posicio.length > 3) {
      print('Comanda invàlida. Format: FilaColumna (ex: B3)');
      continue;
    }

    int fila = posicio.codeUnitAt(0) - 'A'.codeUnitAt(0);
    int columna = int.tryParse(posicio.substring(1)) ?? -1;

    if (fila < 0 || fila >= files || columna < 0 || columna >= columnes) {
      print('Comanda fora de límits.');
      continue;
    }

    if (posarBandera) {
      bandera[fila][columna] = !bandera[fila][columna];
      continue;
    }

    if (destapaCasella(fila, columna, esPrimeraJugada: tirades == 0, esJugadaUsuari: true)) {
      mostrarTauler(finalTauler: true);
      print('Has perdut!');
      print('Número de tirades: $tirades');
      break;
    }

    tirades++;

    if (checkVictoria()) {
      mostrarTauler(finalTauler: true);
      print('Felicitats! Has guanyat!');
      print('Número de tirades: $tirades');
      break;
    }
  }
}

void inicialitzarMines() {
  Random random = Random();
  List<int> quadrants = [0, 0, 0, 0];

  while (quadrants.reduce((a, b) => a + b) < mines) {

    int fila = random.nextInt(files);
    int columna = random.nextInt(columnes);

    if (!minesTauler[fila][columna]) {
      int quadrant = (fila < 3 ? 0 : 2) + (columna < 5 ? 0 : 1);

      if (quadrants[quadrant] < 2 || quadrants.reduce((a, b) => a + b) >= mines - 1) {
        minesTauler[fila][columna] = true;
        quadrants[quadrant]++;
      }
      
    }

  }
}

void mostrarTauler({bool finalTauler = false}) {
  var putCheatNums = mostrarTrampes == true ? "0123456789" : "" ;
  print('  0123456789     '+putCheatNums);

  for (int i = 0; i < files; i++) {
    stdout.write(String.fromCharCode('A'.codeUnitAt(0) + i) + ' ');

    for (int j = 0; j < columnes; j++) {

      if (bandera[i][j]) {

        stdout.write('#');

      } else if (descobert[i][j] || (finalTauler && minesTauler[i][j])) {

        if (minesTauler[i][j]) {

          stdout.write('*');
        } else {

          int numMines = comptaMinesAdjacents(i, j);
          stdout.write(numMines > 0 ? numMines.toString() : ' ');

        }
      } else {

        stdout.write('.');
      }

    }

    if (mostrarTrampes) {

      stdout.write('   ');
      stdout.write(String.fromCharCode('A'.codeUnitAt(0) + i) + ' ');

      for (int j = 0; j < columnes; j++) {
        stdout.write(minesTauler[i][j] ? '*' : '.');
      }

    }

    print(''); 
  }
}




void mostrarAjuda() {
  print('----------------------------------------------------------------------');
  print('Comandes disponibles:');
  print('1. Escollir casella: ex: B3');
  print('2. Posar/treure bandera: ex: B3 bandera o B3 flag');
  print('3. Mostrar/ocultar trampes: trampes o cheat');
  print('4. Ajuda: ajuda o help');
  print('----------------------------------------------------------------------');
}

bool destapaCasella(int x, int y, {required bool esPrimeraJugada, required bool esJugadaUsuari}) {
  if (x < 0 || y < 0 || x >= files || y >= columnes || descobert[x][y] || bandera[x][y]) {
    return false;
  }

  if (minesTauler[x][y]) {
    if (esPrimeraJugada) {
      moureBomba(x, y);

    } else if (esJugadaUsuari) {

      return true;

    } else {

      return false;

    }
  }

  descobert[x][y] = true;

  int numMines = comptaMinesAdjacents(x, y);

  if (numMines == 0) {

    for (int dx = -1; dx <= 1; dx++) {

      for (int dy = -1; dy <= 1; dy++) {

        if (dx != 0 || dy != 0) {
          destapaCasella(x + dx, y + dy, esPrimeraJugada: false, esJugadaUsuari: false);
        }

      }

    }

  }

  return false;
}


void moureBomba(int x, int y) {
  minesTauler[x][y] = false;

  for (int i = 0; i < files; i++) {

    for (int j = 0; j < columnes; j++) {

      if (!descobert[i][j] && !minesTauler[i][j]) {

        minesTauler[i][j] = true;
        return;
      }

    }

  }

}

int comptaMinesAdjacents(int x, int y) {
  int count = 0;

  for (int dx = -1; dx <= 1; dx++) {

    for (int dy = -1; dy <= 1; dy++) {
      int nx = x + dx;
      int ny = y + dy;

      if (nx >= 0 && ny >= 0 && nx < files && ny < columnes && minesTauler[nx][ny]) {
        count++;
      }

    }

  }

  return count;
}

bool checkVictoria() {

  for (int i = 0; i < files; i++) {

    for (int j = 0; j < columnes; j++) {

      if (!descobert[i][j] && !minesTauler[i][j]) {

        return false;
      }

    }

  }
  return true;
}
