//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Loteria {
    address private donoBanca;
    address[] private jogadores;
    address payable private ganhador;
    uint256 private constant VALOR_APOSTA = .0001 ether;
    uint256 private constant VALOR_TAXA = .00001 ether;
    bool private reEntrancyMutex = false;
    event NovaAposta(address jogador, uint256 valor);
    event SorteadoVencedor(address vencedor, uint256 valorGanho);
    enum States {
        Aberta,
        Fechada
    }

    States public state = States.Aberta;

    /***
       TODO : 
       1 ) Percentual da banca 
       2 ) Abrir Banca para apostas
       3 ) Verificar estados antes das apostas -ok 
       https://medium.com/coinmonks/state-machines-in-solidity-9e2d8a6d7a11
     ***/

    constructor() payable {
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

    function sortear() external {
        require(!reEntrancyMutex, "DONO DA BANCA-rentrancy");
        require(msg.sender == donoBanca, "SOMENTE DONO DA BANCA");
        require(state == States.Fechada, "SOMENTE BANCA FECHADA");
        require(jogadores.length > 0, "NAO EXISTE APOSTADORES");

        uint256 idxGanhador = sorteio();
        //obs: futuramente o dono da banca ganha 10%
        uint256 valores = address(this).balance;
        ganhador = payable(jogadores[idxGanhador]);
        reEntrancyMutex = true;
        jogadores = new address[](0);
        ganhador.transfer(valores);
        reEntrancyMutex = false;

        console.log("GANHADOR: %s valor: %s", ganhador, valores);
        emit SorteadoVencedor(ganhador, valores);
    }

    function apostaFechamento() external {
        require(msg.sender == donoBanca, "SOMENTE DONO DA BANCA");
        state = States.Fechada;
    }

    function apostaAbertura() external {
        require(msg.sender == donoBanca, "SOMENTE DONO DA BANCA");
        state = States.Aberta;
    }

    function aberta() public view returns (bool) {
        return (state == States.Aberta);
    }

    function apostaValor() public pure returns (uint256) {
        return VALOR_APOSTA;
    }

    function apostaTaxa() public pure returns (uint256) {
        return VALOR_TAXA;
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

    function apostaTotal() public view returns (uint256) {
        return address(this).balance;
    }

    function apostaDonoBanca() public view returns (address) {
        return donoBanca;
    }

    function apostadores() public view returns (address[] memory) {
        address[] memory _apostadores = jogadores;
        return _apostadores;
    }

    function apostaGanhador() public view returns (address) {
        require(ganhador > address(0), "APOSTADOR NAO DEFINIDO");

        return ganhador;
    }
}
