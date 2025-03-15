public class HelloWorld {
    public String hello() {
        return 'Hello, World!';
    }

    public String unusedMethod() {  // This method is NOT tested
        return 'This is not covered';
    }

    public Integer conditionalMethod(Integer num) { // Partially covered logic
        if (num > 10) {
            return num * 2;
        } else {
            return num - 2; // This branch won't be covered
        }
    }
}