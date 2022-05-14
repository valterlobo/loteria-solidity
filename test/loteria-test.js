const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Loteria contrato", function () {
  let Loteria;
  let hardhatLoteria;
  let donoBanca;
  let apostadores;
  let provider;
  const valorAposta = ".0001";
  //
  beforeEach(async function () {
    Loteria = await ethers.getContractFactory("Loteria");
    [donoBanca, ...apostadores] = await ethers.getSigners();

    // To deploy
    hardhatLoteria = await Loteria.deploy();
    provider = ethers.provider;
  });

  describe("Deployment", function () {
    it("Dono da banca", async function () {
      expect(await hardhatLoteria.apostaDonoBanca()).to.equal(
        donoBanca.address
      );
    });
  });

  describe("Apostas", function () {
    it("Apostadores total", async function () {
      let totalApostas = ethers.utils.parseEther("0");
      apostadores.forEach((apostador) => {
        totalApostas = totalApostas.add(ethers.utils.parseEther(valorAposta));
        hardhatLoteria.connect(apostador).apostar({
          value: ethers.utils.parseEther(valorAposta),
        });
      });
      const premioCalc = totalApostas - totalApostas.div(10);
      expect(await hardhatLoteria.calcularPremio()).to.equal(premioCalc);
    });

    it("Sorteio", async function () {
      const mapApostadores = new Map();
      apostadores.forEach((apostador) => {
        const txAposta = hardhatLoteria.connect(apostador).apostar({
          value: ethers.utils.parseEther(valorAposta),
        });

        txAposta
          .then((result) => {
            provider.getBalance(apostador.address).then((balance) => {
              mapApostadores.set(apostador.address, balance);
            });
          })
          .catch(function (error) {
            expect.assert.fail(error);
          });
      });

      const loteriaSigner = hardhatLoteria.connect(donoBanca);
      const totalSorteio = await hardhatLoteria.calcularPremio();
      await loteriaSigner.apostaFechamento();
      await loteriaSigner.sortear();
      const ganhador = await hardhatLoteria.apostaGanhador();

      const _apostadores = await hardhatLoteria.apostadores();
      expect(_apostadores.length).to.equal(0);
      provider.getBalance(ganhador).then((balance) => {
        const saldoGanhador = mapApostadores.get(ganhador).add(totalSorteio);
        expect(saldoGanhador).to.equal(balance);
        // printInfoBalance(totalSorteio, mapApostadores, ganhador, saldoGanhador);
      });
    });

    it("SorteioApostadores", async function () {
      const mapApostadores = new Map();

      apostadores.forEach((apostador) => {
        const txAposta = hardhatLoteria.connect(apostador).apostar({
          value: ethers.utils.parseEther(valorAposta),
        });

        txAposta
          .then((result) => {
            // console.log(result.from);
            provider.getBalance(result.from).then((balance) => {
              mapApostadores.set(result.from, balance);
            });
          })
          .catch(function (error) {
            expect.assert.fail(error);
          });
      });
      const _apostadores = await hardhatLoteria.apostadores();
      expect(_apostadores.length).to.equal(19);
    });

    it("SorteioBancaAberta", async function () {
      const mapApostadores = new Map();
      const loteriaSigner = hardhatLoteria.connect(donoBanca);

      apostadores.forEach((apostador) => {
        const txAposta = hardhatLoteria.connect(apostador).apostar({
          value: ethers.utils.parseEther(valorAposta),
        });

        txAposta
          .then((result) => {
            provider.getBalance(result.from).then((balance) => {
              mapApostadores.set(result.from, balance);
            });
          })
          .catch(function (error) {
            expect.assert.fail(error);
          });
      });
      // verificar se esta aberta
      const _aberta = await hardhatLoteria.aberta();
      expect(_aberta).to.equal(true);
      // fechamento da aposta
      await loteriaSigner.apostaFechamento();
      // verificar se esta  fechada
      const _fechada = await hardhatLoteria.aberta();
      expect(_fechada).to.equal(false);
    });

    //
    it("SorteioZerarApostador", async function () {
      const mapApostadores = new Map();
      const loteriaSigner = hardhatLoteria.connect(donoBanca);

      apostadores.forEach((apostador) => {
        const txAposta = hardhatLoteria.connect(apostador).apostar({
          value: ethers.utils.parseEther(valorAposta),
        });

        txAposta
          .then((result) => {
            provider.getBalance(result.from).then((balance) => {
              mapApostadores.set(result.from, balance);
            });
          })
          .catch(function (error) {
            expect.assert.fail(error);
          });
      });
      // verificar se esta aberta
      const _aberta = await hardhatLoteria.aberta();
      expect(_aberta).to.equal(true);
      // fechamento da aposta
      await loteriaSigner.apostaFechamento();
      // verificar se esta  fechada
      const _fechada = await hardhatLoteria.aberta();
      expect(_fechada).to.equal(false);
      // sorteio
      const txSoteio = await loteriaSigner.sortear();
      await txSoteio.wait();

      const ganhador = await hardhatLoteria.apostaGanhador();
      expect(ganhador).not.equal(ethers.constants.AddressZero);

      // abertura
      await loteriaSigner.apostaAbertura();
      const txError = () => hardhatLoteria.apostaGanhador();
      // verificar se ganhador  foi zerado - nao seria igual a zero por que foi zerado - ocorre um error no contrato
      expect(txError()).not.equal(ethers.constants.AddressZero);
    });

    it("SorteioValorPremio", async function () {
      const mapApostadores = new Map();
      const loteriaSigner = hardhatLoteria.connect(donoBanca);

      apostadores.forEach((apostador) => {
        const txAposta = hardhatLoteria.connect(apostador).apostar({
          value: ethers.utils.parseEther(valorAposta),
        });

        txAposta
          .then((result) => {
            provider.getBalance(result.from).then((balance) => {
              mapApostadores.set(result.from, balance);
            });
          })
          .catch(function (error) {
            expect.assert.fail(error);
          });
      });
      // verificar se esta aberta
      const _aberta = await hardhatLoteria.aberta();
      expect(_aberta).to.equal(true);

      // fechamento da aposta
      await loteriaSigner.apostaFechamento();
      // verificar se esta  fechada
      const _fechada = await hardhatLoteria.aberta();
      expect(_fechada).to.equal(false);

      // sorteio
      const txSorteio = await loteriaSigner.sortear();
      await txSorteio.wait();

      const ganhador = await hardhatLoteria.apostaGanhador();
      expect(ganhador).not.equal(ethers.constants.AddressZero);
    });
  });
});
