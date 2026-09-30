#include<stdio.h>
#include<inttypes.h>
#include<malloc.h>
#include<string.h>
#define CRC24A_POLY 0b1100001100100110011111011
#define CRC24_MASK 0xFFFFFF
#define CRC24_INIT 0xFFFFFF


static uint32_t crc24_pre_compute_table[256];
// 1100 0011 0010 0110 0111 1101 1000 0000
// C    3     2     6   7   D   8   0
// 0x08D7623C
// inout is a range 
// bot the input and coef should be 24 bits....
uint8_t xor_bits( uint8_t * input, uint8_t * coff, int coff_size)
{
    int i=0; 
    uint8_t xor= 0;

    for( int i =0; i< coff_size ; i++)
    {
        xor ^= input[i] & coff[i]; 
    }
    return xor;
}

char * bin24(uint32_t x)
{
    char * str = malloc(25);
    for (int i =0; i < 24; i++)
    {
        str[i] = (( x >> ( 23-i)) & 0x1) + '0';
       // x >>=1;
    }
    str[24] ='\0';
    return str;
}

void generate_crc_pre_compute_table()
{
    
    uint8_t j =0;
    uint32_t len = 256;
    uint16_t i = 0;
    for ( i =0; i< len; i++)
    {
        uint32_t crc = (i << 16);
        for (j =0; j< 8; ++j)
        {
            if( crc & 0x800000)
            {
                crc = ( crc << 1) ^ CRC24A_POLY;
            }
            else 
            {
                crc <<= 1;
            }
        }

        crc24_pre_compute_table[i] = crc & CRC24_MASK;

    }
}

uint32_t calc_crc_from_table(uint8_t * data, size_t len, uint32_t * table)
{
    // take the percompute values from the tables 
    // and then calculate the CRC... this will save 8*n iterations ....
    uint32_t crc = 0;
    size_t i =0;
    for ( i=0; i< len ; i++)
    {
        uint32_t table_idx = (data[i] ^ ( crc >> 16)) & 0xFF;
        printf("%u \t %u\n", data[i], table_idx);
        crc = ( crc << 8) ^ table[table_idx];
    }
    return crc & CRC24_MASK;
}

uint32_t crc24(uint8_t * data, size_t len)
{
    uint32_t crc = 0;//CRC24_INIT;
    size_t i, j;
    for ( i =0; i< len; i++)
    {
     crc ^=(uint32_t)data[i] << 16;
    for (j =0; j< 8; ++j)
    {
        if( crc & 0x800000)
        {
            crc = ( crc << 1) ^ CRC24A_POLY;
        }
        else 
        {
            crc <<= 1;
        }
    }
    }
    return crc & CRC24_MASK;
}


int parse_str_bits(const char * bit_str, uint8_t * bits_out )
{
    int i =0 ;
    while( *(bit_str + i) )
    {
        char c = *(bit_str + i);
        bits_out[i] = c-'0';
        i++;
    }
    return i;
}

int parse_seq_to_uint8(const char * bits, uint8_t * bytes)
{
    int i =0;
    int b = 0;
    int j =0 ;
    while (*(bits+i) )
    {
        char c = *(bits+i);
        uint8_t x = c-'0';
        if( i % 8 ==0 && i!=0)
        {

            j++;
            bytes[j] = 0;
            b = 0;
        }
        printf("%u,", x);
        bytes[j] += x << (8-b);
        b++;
        i++;
        
    }
    printf("\n");
    return j+1;
}

void print_binary(uint32_t x)
{
    while(x)
    {
        printf("%u", x & 0x1);
        x >>= 1;
    }
    printf("\n");
    
}

void print_bits(uint8_t * bits, int len)
{
    for( int i =0; i< len ; i++)
    {
        printf("%u", bits[i]);
    }
    printf("\n");
}

int bytes(uint32_t x, uint8_t * bytesx)
{
    int i =0;
    while(x)
    {
        bytesx[i] = x & 0xFF;
        x >>= 8;
        i++;
    }
    return i;
}
/// @brief 
/// @param str // input string
/// @param ret_len the return length number of bytes
/// @param rev for rvere 0 NO, 1 Yes
/// @return 
uint8_t * binary_seq_to_bytes(char * str, size_t * ret_len , uint8_t rev)
{
    int len = strlen(str);

    uint32_t mod = ( len %8);

    uint32_t floor = ( len /8);



    *ret_len = ( len + mod)/ 8;

    uint8_t * bytes = (uint8_t *) malloc( *ret_len);

   

    if( bytes == NULL)
    {
        printf("Error ...\n");
        return NULL;
    }
    memset(bytes, 0, *ret_len);
    if( rev == 1)
    {

        for ( int i = len-1; i > 0 ; i--)
        {
            char c = str[i];
            if( c == '1')
            {
                size_t idx = i/8;
                size_t bit_idex = 7-(i%8);
                bytes[idx] += ( 1 << bit_idex);
            }
        }
    }
    else 
    {
        for ( int i = 0; i < len ; i++)
        {
            char c = str[i];
            if( c == '1')
            {
                size_t idx = i/8;
                size_t bit_idex = 7-(i%8);
                bytes[idx] += ( 1 << bit_idex);
            }
        }
    }
    return bytes;
}

int main(int argc , char ** argv)
{
   
    // it's working but you needs to add padding zeros, so that they must be multiple of 24 bits..
    if( argc == 1) 
    {
        printf("%s bin_seq \n", argv[0]);
        return 0;
    }

    char * seq = argv[1];

    size_t len = 0;
    uint8_t rev = 0;
    uint32_t crc = 0;

    // uint8_t * bytes = binary_seq_to_bytes(seq, &len , rev);

    uint8_t * bytes = (uint8_t * ) malloc(8);
    len = 8;

    for ( int i =0; i<len ; i++)
    {
        bytes[i] = 7-i;
        //printf("0x%02X, ", bytes[i]);
    }
    printf("\n");

    generate_crc_pre_compute_table();

    crc = calc_crc_from_table(bytes, len, crc24_pre_compute_table);

     char * _bin = bin24(crc);

    printf("CRC = 0x%06X \t %s \n", crc, _bin);

    printf("-------------------\n");

    crc = crc24(bytes, len);

    _bin = bin24(crc);

    printf("CRC = 0x%06X \t %s \n ", crc, _bin);

    //   for ( int i =0; i< 256 ; i++)
    //   {
    //      uint32_t crc = crc24_pre_compute_table[i];
    //      char * _bin = bin24(crc);
    //      printf("%u \t 0x%06X \t %s \n", i, crc, _bin);
    //   }

    return 0;
    // 


}