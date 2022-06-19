//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "hardhat/console.sol";

contract Loteria {
    address private donoBanca;
    address[] private jogadores;
    address payable private ganhador;
    uint256 private constant VALOR_APOSTA = .0001 ether;
    uint256 private constant VALOR_TAXA = .00001 ether;
    //bool private reEntrancyMutex = false;
    event NovaAposta(address jogador, uint256 valor);
    event SorteadoVencedor(address vencedor, uint256 valorGanho);
    enum States {
        Aberta,
        Fechada,
        Sorteio
    }

    States public state = States.Aberta;

    /***
       TODO : 
       1 ) Percentual da banca 
       2 ) Abrir Banca para apostas -OK 
       3 ) Verificar estados antes das apostas -OK 
       4 ) alterar o require para modifier! 
       https://medium.com/coinmonks/state-machines-in-solidity-9e2d8a6d7a11
     ***/

    constructor() payable {
        require(address(msg.sender) != address(0), "ADDRESS ZERO");
        donoBanca = msg.sender;
    }

    //apostar
    function apostar() external payable {
        require(msg.value == VALOR_APOSTA, "VALOR DA APOSTA .0001 ether");

        require(state == States.Aberta, "BANCA FECHADA");
        jogadores.push(msg.sender);
        emit NovaAposta(msg.sender, msg.value);
        //console.log("Apostador: %s valor: %s", msg.sender ,  msg.value );
    }

    function sorteio() private view returns (uint256) {
        //10 - 0 - 9
        //5  - 0 - 4
        // (109)%5 = 1
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, jogadores)
            )
        );
        uint256 sorteado;
        console.log("random: %s | length: %s", random, jogadores.length);
        sorteado = random % jogadores.length;
        return sorteado;
    }

    function sortear() external {
        //require(!reEntrancyMutex, "DONO DA BANCA-rentrancy");
        require(msg.sender == donoBanca, "SOMENTE DONO DA BANCA");
        require(state == States.Fechada, "SOMENTE BANCA FECHADA");
        require(jogadores.length > 0, "NAO EXISTE APOSTADORES");

        uint256 idxGanhador = sorteio();
        uint256 valorPremio = calcularPremio();
        ganhador = payable(jogadores[idxGanhador]);
        //reEntrancyMutex = true;
        jogadores = new address[](0);
        console.log("GANHADOR: %s valor: %s", ganhador, valorPremio);
        emit SorteadoVencedor(ganhador, valorPremio);
        ganhador.transfer(valorPremio);
        //reEntrancyMutex = false;
    }

    function apostaFechamento() external {
        require(msg.sender == donoBanca, "SOMENTE DONO DA BANCA");
        state = States.Fechada;
    }

    function apostaAbertura() external {
        require(msg.sender == donoBanca, "SOMENTE DONO DA BANCA");
        state = States.Aberta;
        ganhador = payable(0);
    }

    function apostaRetirada(uint256 valor) external {
        require(address(msg.sender) != address(0), "ADDRESS ZERO");
        require(msg.sender == donoBanca, "SOMENTE DONO DA BANCA");
        require(valor > 0, "MAIOR QUE ZERO");
        require(address(this).balance > valor, "SALDO INSUFICIENTE");

        address payable _to = payable(msg.sender);
        require(_to != address(0), "ADDRESS ZERO");
        _to.transfer(valor);
    }

    function aberta() external view returns (bool) {
        return (state == States.Aberta);
    }

    function apostaValor() external pure returns (uint256) {
        return VALOR_APOSTA;
    }

    function apostaTaxa() external pure returns (uint256) {
        return VALOR_TAXA;
    }

    function calcularPremio() public view returns (uint256) {
        require(jogadores.length > 0, "NAO EXISTE APOSTADORES");

        uint256 totalApostadores = jogadores.length;
        uint256 premio = (totalApostadores * VALOR_APOSTA) -
            (totalApostadores * VALOR_TAXA);

        return premio;
    }

    function apostaTotal() external view returns (uint256) {
        if (jogadores.length > 0) {
            return jogadores.length * VALOR_APOSTA;
        }
        return 0;
    }

    function apostaDonoBanca() external view returns (address) {
        return donoBanca;
    }

    function apostadores() external view returns (address[] memory) {
        address[] memory _apostadores = jogadores;
        return _apostadores;
    }

    function apostaGanhador() external view returns (address) {
        require(ganhador > address(0), "APOSTADOR NAO DEFINIDO");
        return ganhador;
    }
}
