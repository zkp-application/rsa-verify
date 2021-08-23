const path = require("path");

const bigInt = require("big-integer");
const Scalar = require("ffjavascript").Scalar;
const tester = require("circom").tester;

const { splitToArray } = require("./util.js");


describe("Montgomery exponent 64bits/32words", function () {
    this.timeout(100000);

    let circuit;
    before(async () => {
        circuit = await tester(path.join(__dirname, "circuits", "mont_exp.circom"));
    });

    it("64bits/32words. Montgomery exponent", async () => {

        const modulus = bigInt("27333278531038650284292446400685983964543820405055158402397263907659995327446166369388984969315774410223081038389734916442552953312548988147687296936649645550823280957757266695625382122565413076484125874545818286099364801140117875853249691189224238587206753225612046406534868213180954324992542640955526040556053150097561640564120642863954208763490114707326811013163227280580130702236406906684353048490731840275232065153721031968704703853746667518350717957685569289022049487955447803273805415754478723962939325870164033644600353029240991739641247820015852898600430315191986948597672794286676575642204004244219381500407");

        const m0inv = "12890617734997456953";

        const sign = bigInt("27166015521685750287064830171899789431519297967327068200526003963687696216659347317736779094212876326032375924944649760206771585778103092909024744594654706678288864890801000499430246054971129440518072676833029702477408973737931913964693831642228421821166326489172152903376352031367604507095742732994611253344812562891520292463788291973539285729019102238815435155266782647328690908245946607690372534644849495733662205697837732960032720813567898672483741410294744324300408404611458008868294953357660121510817012895745326996024006347446775298357303082471522757091056219893320485806442481065207020262668955919408138704593");

        // p_A = (2 ** (64 * 32)) % modulus
        const p_A = bigInt("1").shiftLeft(bigInt(64 * 32)).mod(modulus);

        // p_a = (a * r) % modulus
        const p_a = sign.shiftLeft(bigInt(64 * 32)).mod(modulus);

        const result = sign.modPow(bigInt("65537"), modulus);


        const hashed = bigInt("83814198383102558219731078260892729932246618004265700685467928187377105751529");
        
        var testCases = [{
            description: "calc powerMod",
            input: {
                // 1844674407370955161600
                p_a: splitToArray(p_a, 64, 32),
                p_A: splitToArray(p_A, 64, 32),

                exp: 65537,
                p: splitToArray(modulus, 64, 32),
                m0ninv: m0inv,
            },
            output: { out: splitToArray(result, 64, 32) },
        }];


        for (var i = 0; i < testCases.length; i++) {
            const witness = await circuit.calculateWitness(testCases[i].input, true);

            await circuit.assertOut(witness, testCases[i].output);
        }
    });
});


