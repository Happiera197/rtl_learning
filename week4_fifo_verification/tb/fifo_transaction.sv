class fifo_transaction;
bit write;
bit read;
logic [7:0]data;

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
            "[%s] write=%0d read=%0d data=0x%02h",
            prefix,
            write,
            read,
            data);
endfunction

function fifo_transaction copy();
    fifo_transaction tmp;
    tmp=new();
    tmp.write=this.write;
    tmp.read  = this.read;
    tmp.data  = this.data;

    return tmp;
endfunction

function bit compare(fifo_transaction rhs);
    if(rhs==null) return 0;
    return(
        (write==rhs.write)&&(read==rhs.read)&&(data==rhs.data)
    );
endfunction

function void legalize(
        input int unsigned level,
        input int unsigned depth
    );

    if(level==0) read=1'b0;
    if((level>=depth)&&!read)write=1'b0;
endfunction

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
endfunction

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
endclass
