const Controller = artifacts.require('Controller')
const RErc20 = artifacts.require('RErc20')
const RTT = artifacts.require('RTT')

contract('E2E Testing', function() {
  it('quick tests for controller and all r-tokens', async function () {
    const controller = await Controller.at('0x0d4fe8832857Bb557d8CFCf3737cbFc8aE784106');
    assert.isTrue(await controller.isController())

    const rTTAddress = await controller.allMarkets(0)
    const rTT = await RTT.at(rTTAddress)
    assert.isTrue(BigInt(await rTT.getCash()) > 0n)

    for (let i = 1; i < 5; i++) {
      const address = await controller.allMarkets(i)
      const rToken = await RErc20.at(address)
      const cash = BigInt(await rToken.getCash())
      assert.isTrue(cash > 0n)
    }
  });
});
