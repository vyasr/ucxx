import asyncio

import pytest

import ucxx


@pytest.mark.asyncio
@pytest.mark.parametrize("server_close_callback", [True, False])
async def test_close_callback(server_close_callback):
    closed = [False]

    def _close_callback():
        closed[0] = True

    async def server_node(ep):
        if server_close_callback is True:
            ep.set_close_callback(_close_callback)

    async def client_node(port):
        ep = await ucxx.create_endpoint(
            ucxx.get_address(),
            port,
        )
        if server_close_callback is False:
            ep.set_close_callback(_close_callback)

    listener = ucxx.create_listener(
        server_node,
    )
    await client_node(listener.port)
    while closed[0] is False:
        await asyncio.sleep(0.01)


@pytest.mark.asyncio
@pytest.mark.parametrize("transfer_api", ["am", "tag"])
async def test_cancel(transfer_api):
    if transfer_api == "am":
        pytest.skip("AM not implemented yet")

    async def server_node(ep):
        pass

    async def client_node(port):
        ep = await ucxx.create_endpoint(ucxx.get_address(), port)
        try:
            if transfer_api == "am":
                await ep.am_recv()
            else:
                msg = bytearray(1)
                await ep.recv(msg)
        except Exception as e:
            await ep.close()
            raise e

    listener = ucxx.create_listener(server_node)
    with pytest.raises(
        ucxx.exceptions.UCXCanceledError,
        # TODO: Add back custom UCXCanceledError messages?
    ):
        await client_node(listener.port)
    listener.close()
