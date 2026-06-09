document.getElementById('draw').addEventListener('click', function () {
    const omikujiReuslts = ['大吉','中吉','小吉','末吉','凶'];
    const result = omikujiReuslts[
        Math.floor(Math.random() * omikujiReuslts.length)
    ];
    console.log(result);
    document.getElementById('result').textContent =
    `あなたの運勢は...${result}!`;
})