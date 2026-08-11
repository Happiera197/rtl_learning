
`include "fifo_transaction.sv"
module tb_transaction;

    fifo_transaction tr1;
    fifo_transaction tr2;
    fifo_transaction tr3;
initial begin

        $display("============================");
        $display("Create tr1");
        $display("============================");

        tr1 = new(1, 0, 8'h55);

        tr1.display("tr1");


        $display("");
        $display("============================");
        $display("Handle Assignment");
        $display("============================");

        tr2 = tr1;

        tr1.display("tr1");
        tr2.display("tr2");

        $display("Modify tr2.data to AA");

        tr2.data = 8'hAA;

        tr1.display("tr1");
        tr2.display("tr2");


        $display("");
        $display("============================");
        $display("Object Copy");
        $display("============================");

        tr3 = tr1.copy();

        tr1.display("tr1");
        tr3.display("tr3");

        $display("Modify tr3.data to FF");

        tr3.data = 8'hFF;

        tr1.display("tr1");
        tr3.display("tr3");


        $display("");
        $display("============================");
        $display("Compare");
        $display("============================");

        if (tr1.compare(tr2))
            $display("tr1 and tr2 have same contents");
        else
            $display("tr1 and tr2 have different contents");

        if (tr1.compare(tr3))
            $display("tr1 and tr3 have same contents");
        else
            $display("tr1 and tr3 have different contents");


        $display("");
        $display("TEST DONE");

        $finish;

end

endmodule
