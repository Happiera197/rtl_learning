class fifo_transaction;
rand bit write;
rand bit read;
rand logic [7:0]data;
logic [7:0] rdata;
bit         empty;
bit         full;
int unsigned count;

function new(
    bit write=0,
    bit read=0,
    logic [7:0]data='0
);
    this.write=write;
    this.read=read;
    this.data=data;

endfunction

function void display(
    input string prefix = "FIFO_TRANSACTION"
);
    $display(
    "[%s] wr=%0b rd=%0b din=0x%02h dout=0x%02h empty=%0b full=%0b count=%0d",
    prefix,
    write,
    read,
    data,
    rdata,
    empty,
    full,
    count
);
endfunction

function fifo_transaction copy();
    fifo_transaction tmp;
    tmp=new();
    tmp.write=this.write;
    tmp.read  = this.read;
    tmp.data  = this.data;
    tmp.rdata  = this.rdata;
    tmp.empty = this.empty;
    tmp.full  = this.full;
    tmp.count = this.count;

    return tmp;
endfunction

function bit compare(fifo_transaction rhs);
    if(rhs==null) return 0;
    return(
    (write == rhs.write) &&
    (read  == rhs.read ) &&
    (data  == rhs.data ) &&
    (rdata  == rhs.rdata ) &&
    (empty == rhs.empty) &&
    (full  == rhs.full ) &&
    (count == rhs.count));
endfunction

function void legalize(
        input int unsigned level,
        input int unsigned depth
    );

    if(level==0) read=1'b0;
    if((level>=depth)&&!read)write=1'b0;
endfunction
/*
function void randomize_fallback(
        input int unsigned level,
        input int unsigned depth
    );
    int unsigned r;
    data=8'($urandom_range(255,0));
    r=$urandom_range(99,0);
    if(level<=1)begin
        if (r < 55)
            {write, read} = 2'b10;

        else if (r < 75)
            {write, read} = 2'b11;

        else if (r < 90)
            {write, read} = 2'b00;

        else
            {write, read} = 2'b01;

    end
    else if (level >= depth - 1) begin

            if (r < 55)
                {write, read} = 2'b01;

            else if (r < 75)
                {write, read} = 2'b11;

            else if (r < 90)
                {write, read} = 2'b00;

            else
                {write, read} = 2'b10;

        end
         else begin

            if (r < 30)
                {write, read} = 2'b10;

            else if (r < 60)
                {write, read} = 2'b01;

            else if (r < 90)
                {write, read} = 2'b11;

            else
                {write, read} = 2'b00;

        end
        legalize(
            level,
            depth
        );
endfunction*/

function void force_write();

        write = 1'b1;
        read  = 1'b0;
        data  = 8'($urandom_range(255, 0));

    endfunction

function void force_read();

        write = 1'b0;
        read  = 1'b1;
        data  = '0;

    endfunction

function void force_rw();

        write = 1'b1;
        read  = 1'b1;
        data  = 8'($urandom_range(255, 0));

    endfunction

    constraint operation_c {

        {write, read} dist {
            2'b10 := 30,
            2'b01 := 30,
            2'b11 := 30,
            2'b00 := 10
        };

    }
    constraint data_c {

        if (!write)
            data == '0;

    }

endclass
